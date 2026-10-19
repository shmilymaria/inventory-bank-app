<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Barang;
use App\Services\PermintaanService;
use App\Support\AlurPermintaan;
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
            ->select(
                'permintaan.*',
                DB::raw('(SELECT COUNT(*) FROM detail_permintaan d ' .
                        'WHERE d.permintaan_id = permintaan.id) AS total_item')
            )
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
                'barang.gambar',
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

        // Seluruh riwayat keputusan (tahap Admin & Pimpinan), terbaru di atas.
        // `nama_pimpinan` berisi nama pengambil keputusan, `tahap` = Admin/Pimpinan.
        $riwayatApproval = DB::table('approval')
            ->join('users', 'approval.pimpinan_id', '=', 'users.id')
            ->select('approval.*', 'users.nama_lengkap as nama_pimpinan')
            ->where('approval.permintaan_id', $id)
            ->orderBy('approval.tanggal_approval', 'desc')
            ->get();

        $status = $permintaan->status_permintaan;

        return response()->json([
            'success' => true,
            'data'    => [
                'permintaan'        => $permintaan,
                'detail_items'      => $detailItems,
                'approval'          => $approval,
                'riwayat_approval'  => $riwayatApproval,
                'riwayat_perubahan' => AlurPermintaan::riwayatPerubahan($id),

                // Alur & aksi yang boleh dilakukan User saat ini
                'butuh_pimpinan'    => AlurPermintaan::butuhPimpinan($permintaan->prioritas),
                'keterangan_alur'   => AlurPermintaan::keteranganAlur($permintaan->prioritas),
                'bisa_edit'         => $status === 'Pending',
                'bisa_batal'        => $status === 'Pending',
                'bisa_revisi'       => $status === 'Revision',
                'tahap_revisi'      => $status === 'Revision'
                    ? AlurPermintaan::tahapRevisiTerakhir($id) : null,
                'siap_diambil'      => AlurPermintaan::siapDistribusi($permintaan)
                    && !empty($permintaan->qr_token),
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
                'barang.gambar',
                'barang.stok',
                'barang.satuan',
                'barang.status_barang',
                'barang.kategori_id',
                'kategori_barang.nama_kategori',
                // ATK / Barang Cetakan / Barang Lainnya (untuk tombol kategori di katalog)
                DB::raw(AlurPermintaan::kelompokKategoriSql() . ' AS kelompok_kategori')
            )
            // Catatan: barang dengan status "Habis" tetap dikirim ke mobile
            // (tidak difilter) supaya tetap tampil di katalog, hanya saja
            // ditampilkan abu-abu/nonaktif di sisi aplikasi mobile.
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

        $hasil = PermintaanService::buat(
            $this->authUser($request),
            $request->prioritas,
            $request->catatan,
            $request->items
        );

        return $this->balas($hasil);
    }

    // ----------------------------------------------------------------
    // PUT /api/permintaan/{id} — edit permintaan (hanya status Pending)
    // ----------------------------------------------------------------
    public function update(Request $request, int $id)
    {
        return $this->ubah($request, $id, 'edit');
    }

    // ----------------------------------------------------------------
    // PUT /api/permintaan/{id}/revisi — kirim ulang revisi (status Revision)
    // Permintaan & nomor yang sama, tidak membuat permintaan baru.
    // ----------------------------------------------------------------
    public function revisi(Request $request, int $id)
    {
        return $this->ubah($request, $id, 'revisi');
    }

    // ----------------------------------------------------------------
    // POST /api/permintaan/{id}/batal — batalkan (hanya status Pending)
    // ----------------------------------------------------------------
    public function batalkan(Request $request, int $id)
    {
        return $this->balas(
            PermintaanService::batalkan($id, $this->authUser($request))
        );
    }

    // ── Helper bersama edit & revisi ──────────────────────────────
    private function ubah(Request $request, int $id, string $mode)
    {
        $request->validate([
            'prioritas'         => 'required|in:Normal,Penting,Mendesak',
            'catatan'           => 'nullable|string|max:500',
            'items'             => 'required|array|min:1',
            'items.*.detail_id' => 'required|integer',
            'items.*.jumlah'    => 'required|integer|min:1',
        ]);

        $hasil = PermintaanService::ubah(
            $id,
            $this->authUser($request),
            $mode,
            $request->prioritas,
            $request->catatan,
            $request->items
        );

        return $this->balas($hasil);
    }

    private function balas(array $hasil)
    {
        $body = ['success' => $hasil['ok'], 'message' => $hasil['message']];
        if (isset($hasil['data'])) {
            $body['data'] = $hasil['data'];
        }
        return response()->json($body, $hasil['kode'] ?? ($hasil['ok'] ? 200 : 422));
    }
}
