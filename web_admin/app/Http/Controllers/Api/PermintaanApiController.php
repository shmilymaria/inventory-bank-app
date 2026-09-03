<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Barang;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PermintaanApiController extends Controller
{
    // ── Helper ambil auth_user ────────────────────────────
    private function authUser(Request $request)
    {
        return $request->attributes->get('auth_user');
    }

    // ----------------------------------------------------------------
    // GET /api/permintaan
    // ----------------------------------------------------------------
    public function index(Request $request)
    {
        $user  = $this->authUser($request);
        $query = DB::table('permintaan')
            ->where('user_id', $user->id);

        if ($request->filled('status')) {
            $query->where('status_permintaan', $request->status);
        }

        $permintaan = $query->orderBy('id', 'desc')->get();

        return response()->json([
            'success' => true,
            'data'    => $permintaan,
        ]);
    }

    // ----------------------------------------------------------------
    // GET /api/permintaan/{id}
    // ----------------------------------------------------------------
    public function show(Request $request, int $id)
    {
        $user = $this->authUser($request);

        $permintaan = DB::table('permintaan')
            ->where('id', $id)
            ->where('user_id', $user->id)
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
                'barang.stok',
                'kategori_barang.nama_kategori'
            )
            ->where('detail_permintaan.permintaan_id', $id)
            ->get();

        $approval = DB::table('approval')
            ->join('users', 'approval.pimpinan_id', '=', 'users.id')
            ->select('approval.*', 'users.nama_lengkap as nama_pimpinan')
            ->where('approval.permintaan_id', $id)
            ->latest('approval.tanggal_approval')
            ->first();

        return response()->json([
            'success' => true,
            'data'    => [
                'permintaan'   => $permintaan,
                'detail_items' => $detailItems,
                'approval'     => $approval,
            ],
        ]);
    }

    // ----------------------------------------------------------------
    // GET /api/barang — daftar barang untuk form permintaan
    // ----------------------------------------------------------------
    public function daftarBarang(Request $request)
    {
        $barang = DB::table('barang')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select(
                'barang.id',
                'barang.kode_barang',
                'barang.nama_barang',
                'barang.stok',
                'barang.satuan',
                'barang.status_barang',
                'kategori_barang.nama_kategori'
            )
            ->where('barang.status_barang', '!=', 'Habis')
            ->orderBy('kategori_barang.nama_kategori')
            ->orderBy('barang.nama_barang')
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $barang,
        ]);
    }

    // ----------------------------------------------------------------
    // POST /api/permintaan — ajukan permintaan baru
    // ----------------------------------------------------------------
    public function store(Request $request)
    {
        $request->validate([
            'prioritas'          => 'required|in:Normal,Penting,Mendesak',
            'catatan'            => 'nullable|string|max:500',
            'items'              => 'required|array|min:1',
            'items.*.barang_id'  => 'required|exists:barang,id',
            'items.*.jumlah'     => 'required|integer|min:1',
            'items.*.keterangan' => 'nullable|string',
        ]);

        $user = $this->authUser($request);

        // Generate nomor permintaan
        $tahun = date('Y');
        $bulan = date('m');
        $count = DB::table('permintaan')
            ->whereYear('created_at', $tahun)
            ->whereMonth('created_at', $bulan)
            ->count() + 1;
        $nomor = 'REQ-' . $tahun . $bulan . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);

        DB::transaction(function () use ($request, $user, $nomor) {

            // Simpan header permintaan
            $permintaanId = DB::table('permintaan')->insertGetId([
                'nomor_permintaan'   => $nomor,
                'user_id'            => $user->id,
                'tanggal_permintaan' => now(),
                'prioritas'          => $request->prioritas,
                'catatan'            => $request->catatan,
                'status_permintaan'  => 'Pending',
                'created_at'         => now(),
            ]);

            // Simpan detail item
            foreach ($request->items as $item) {
                DB::table('detail_permintaan')->insert([
                    'permintaan_id' => $permintaanId,
                    'barang_id'     => $item['barang_id'],
                    'jumlah'        => $item['jumlah'],
                    'keterangan'    => $item['keterangan'] ?? null,
                ]);
            }

            // Kirim notifikasi ke semua Pimpinan
            $pimpinan = DB::table('users')
                ->where('role_id', 3)
                ->where('status_aktif', 'Aktif')
                ->get();

            foreach ($pimpinan as $p) {
                DB::table('notifikasi')->insert([
                    'user_id'     => $p->id,
                    'judul'       => 'Permintaan Baru Masuk',
                    'pesan'       => 'Permintaan ' . $nomor . ' dari ' .
                                     $user->nama_lengkap . ' (' .
                                     ($user->bagian ?? '-') .
                                     ') menunggu persetujuan Anda.',
                    'status_baca' => 'Belum Dibaca',
                    'created_at'  => now(),
                ]);
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Permintaan berhasil diajukan dengan nomor ' . $nomor . '.',
            'data'    => ['nomor_permintaan' => $nomor],
        ], 201);
    }
}