<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Services\VerifikasiService;
use App\Support\AlurPermintaan;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Tahap 1 approval — Admin (bagian umum) memverifikasi permintaan User
 * sebelum diteruskan ke Pimpinan.
 */
class VerifikasiApiController extends Controller
{
    private function authUser(Request $request)
    {
        return $request->attributes->get('auth_user');
    }

    private function pastikanAdmin(Request $request)
    {
        $user = $this->authUser($request);
        if ((int) $user->role_id !== 1) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak. Fitur ini khusus Admin.',
            ], 403);
        }
        return null;
    }

    // ----------------------------------------------------------------
    // GET /api/admin/verifikasi
    // Daftar permintaan yang menunggu verifikasi Admin (status Pending)
    // ----------------------------------------------------------------
    public function index(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $daftar = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->select(
                'permintaan.*',
                'users.nama_lengkap',
                'users.bagian',
                'users.jabatan'
            )
            ->where('permintaan.status_permintaan', 'Pending')
            ->orderBy('permintaan.id', 'asc') // yang paling lama menunggu di atas
            ->get()
            ->map(function ($p) {
                $p->total_item     = DB::table('detail_permintaan')
                    ->where('permintaan_id', $p->id)->count();
                $p->butuh_pimpinan = AlurPermintaan::butuhPimpinan($p->prioritas);
                return $p;
            });

        return response()->json(['success' => true, 'data' => $daftar]);
    }

    // ----------------------------------------------------------------
    // GET /api/admin/verifikasi/{id}
    // ----------------------------------------------------------------
    public function show(Request $request, int $id)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

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
            ->select('approval.*', 'users.nama_lengkap as nama_pengambil_keputusan')
            ->where('approval.permintaan_id', $id)
            ->orderBy('approval.tanggal_approval', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => [
                'permintaan'        => $permintaan,
                'detail_items'      => $detailItems,
                'riwayat_approval'  => $riwayatApproval,
                'riwayat_perubahan' => AlurPermintaan::riwayatPerubahan($id),
                // Apa yang terjadi setelah Admin menyetujui?
                'butuh_pimpinan'    => AlurPermintaan::butuhPimpinan($permintaan->prioritas),
                'keterangan_alur'   => AlurPermintaan::keteranganAlur($permintaan->prioritas),
                'siap_distribusi'   => AlurPermintaan::siapDistribusi($permintaan),
            ],
        ]);
    }

    // ----------------------------------------------------------------
    // POST /api/admin/verifikasi/{id}
    // Body: keputusan (Approved|Rejected|Revision), catatan_approval
    // ----------------------------------------------------------------
    public function store(Request $request, int $id)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $request->validate([
            'keputusan'        => 'required|in:Approved,Rejected,Revision',
            'catatan_approval' => 'nullable|string|max:500',
        ]);

        $hasil = VerifikasiService::proses(
            $id,
            $this->authUser($request),
            $request->keputusan,
            $request->catatan_approval
        );

        return response()->json([
            'success' => $hasil['ok'],
            'message' => $hasil['message'],
        ], $hasil['ok'] ? 200 : 422);
    }

    // ----------------------------------------------------------------
    // GET /api/admin/verifikasi-riwayat
    // Keputusan verifikasi yang sudah diambil Admin (semua Admin)
    // ----------------------------------------------------------------
    public function riwayat(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $riwayat = DB::table('approval')
            ->join('permintaan', 'approval.permintaan_id', '=', 'permintaan.id')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->join('users as admin', 'approval.pimpinan_id', '=', 'admin.id')
            ->select(
                'approval.*',
                'permintaan.nomor_permintaan',
                'permintaan.prioritas',
                'permintaan.status_permintaan',
                'users.nama_lengkap as nama_pemohon',
                'users.bagian',
                'admin.nama_lengkap as nama_admin'
            )
            ->where('approval.tahap', 'Admin')
            ->orderBy('approval.tanggal_approval', 'desc')
            ->limit(30)
            ->get();

        return response()->json(['success' => true, 'data' => $riwayat]);
    }
}
