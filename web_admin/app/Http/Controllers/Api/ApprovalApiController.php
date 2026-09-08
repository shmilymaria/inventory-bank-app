<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ApprovalApiController extends Controller
{
    // ── Helper ambil auth_user ────────────────────────────
    private function authUser(Request $request)
    {
        return $request->attributes->get('auth_user');
    }

    // ----------------------------------------------------------------
    // GET /api/approval
    // ----------------------------------------------------------------
    public function index(Request $request)
    {
        $query = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->select(
                'permintaan.*',
                'users.nama_lengkap',
                'users.bagian',
                'users.jabatan'
            );

        if ($request->filled('status')) {
            $query->where('permintaan.status_permintaan', $request->status);
        } else {
            $query->where('permintaan.status_permintaan', 'Pending');
        }

        $permintaan = $query->orderBy('permintaan.id', 'desc')->get();

        return response()->json([
            'success' => true,
            'data'    => $permintaan,
        ]);
    }

    // ----------------------------------------------------------------
    // GET /api/approval/{id}
    // ----------------------------------------------------------------
    public function show(Request $request, int $id)
    {
        $permintaan = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->select(
                'permintaan.*',
                'users.nama_lengkap',
                'users.bagian',
                'users.jabatan',
                'users.nomor_hp',
                'users.email'
            )
            ->where('permintaan.id', $id)
            ->first();

        if (!$permintaan) {
            return response()->json([
                'success' => false,
                'message' => 'Data permintaan tidak ditemukan.',
            ], 404);
        }

        $detailItems = DB::table('detail_permintaan')
            ->join('barang', 'detail_permintaan.barang_id', '=', 'barang.id')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select(
                'detail_permintaan.*',
                'barang.kode_barang',
                'barang.nama_barang',
                'barang.satuan',
                'barang.stok as stok_tersedia',
                'kategori_barang.nama_kategori'
            )
            ->where('detail_permintaan.permintaan_id', $id)
            ->get();

        $riwayatApproval = DB::table('approval')
            ->join('users', 'approval.pimpinan_id', '=', 'users.id')
            ->select('approval.*', 'users.nama_lengkap as nama_pimpinan')
            ->where('approval.permintaan_id', $id)
            ->orderBy('approval.tanggal_approval', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'permintaan'       => $permintaan,
                'detail_items'     => $detailItems,
                'riwayat_approval' => $riwayatApproval,
            ],
        ]);
    }

    // ----------------------------------------------------------------
    // POST /api/approval/{id}
    // ----------------------------------------------------------------
    public function store(Request $request, int $id)
    {
        $request->validate([
            'keputusan'        => 'required|in:Approved,Rejected,Revision',
            'catatan_approval'  => 'nullable|string|max:500',
        ]);

        $pimpinan   = $this->authUser($request);
        $permintaan = DB::table('permintaan')
            ->where('id', $id)
            ->whereIn('status_permintaan', ['Pending', 'Revision'])
            ->first();

        if (!$permintaan) {
            return response()->json([
                'success' => false,
                'message' => 'Permintaan tidak ditemukan atau sudah diproses.',
            ], 404);
        }

        DB::transaction(function () use ($request, $id, $permintaan, $pimpinan) {

            DB::table('approval')->insert([
                'permintaan_id'    => $id,
                'pimpinan_id'      => $pimpinan->id,
                'keputusan'        => $request->keputusan,
                'catatan_approval' => $request->catatan_approval,
                'tanggal_approval' => now(),
            ]);

            $dataUpdatePermintaan = [
                'status_permintaan' => $request->keputusan,
            ];

            // Kalau disetujui, generate QR token unik untuk konfirmasi
            // Outbound (ditampilkan di HP User, discan Admin saat serah terima).
            if ($request->keputusan === 'Approved') {
                $dataUpdatePermintaan['qr_token']         = Str::random(40);
                $dataUpdatePermintaan['qr_generated_at']  = now();
            }

            DB::table('permintaan')->where('id', $id)->update($dataUpdatePermintaan);

            $pesanMap = [
                'Approved' => 'Permintaan ' . $permintaan->nomor_permintaan .
                              ' Anda telah DISETUJUI oleh ' . $pimpinan->nama_lengkap .
                              '. Barang akan segera didistribusikan.',
                'Rejected' => 'Permintaan ' . $permintaan->nomor_permintaan .
                              ' Anda telah DITOLAK oleh ' . $pimpinan->nama_lengkap .
                              ($request->catatan_approval
                                  ? '. Catatan: ' . $request->catatan_approval : '.'),
                'Revision' => 'Permintaan ' . $permintaan->nomor_permintaan .
                              ' perlu DIREVISI. Catatan dari Pimpinan: ' .
                              ($request->catatan_approval ?? '-'),
            ];

            DB::table('notifikasi')->insert([
                'user_id'     => $permintaan->user_id,
                'judul'       => 'Update Status Permintaan',
                'pesan'       => $pesanMap[$request->keputusan],
                'status_baca' => 'Belum Dibaca',
                'created_at'  => now(),
            ]);

            // Kalau disetujui, kabari semua Admin supaya tahu ada
            // barang yang siap diproses (Scan Checkout & Outbound).
            if ($request->keputusan === 'Approved') {
                $adminIds = DB::table('users')->where('role_id', 1)->pluck('id');
                foreach ($adminIds as $adminId) {
                    DB::table('notifikasi')->insert([
                        'user_id'     => $adminId,
                        'judul'       => 'Permintaan Siap Didistribusikan',
                        'pesan'       => 'Permintaan ' . $permintaan->nomor_permintaan .
                                         ' sudah disetujui Pimpinan dan siap diproses ' .
                                         '(Scan Checkout & Outbound).',
                        'status_baca' => 'Belum Dibaca',
                        'created_at'  => now(),
                    ]);
                }
            }
        });

        $pesanSukses = [
            'Approved' => 'Permintaan berhasil disetujui.',
            'Rejected' => 'Permintaan berhasil ditolak.',
            'Revision' => 'Permintaan berhasil dikembalikan untuk revisi.',
        ];

        return response()->json([
            'success' => true,
            'message' => $pesanSukses[$request->keputusan],
        ]);
    }

    // ----------------------------------------------------------------
    // GET /api/riwayat-approval
    // ----------------------------------------------------------------
    public function riwayat(Request $request)
    {
        $pimpinan = $this->authUser($request);

        $riwayat = DB::table('approval')
            ->join('permintaan', 'approval.permintaan_id', '=', 'permintaan.id')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->select(
                'approval.*',
                'permintaan.nomor_permintaan',
                'permintaan.prioritas',
                'users.nama_lengkap as nama_pemohon',
                'users.bagian'
            )
            ->where('approval.pimpinan_id', $pimpinan->id)
            ->orderBy('approval.tanggal_approval', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $riwayat,
        ]);
    }
}