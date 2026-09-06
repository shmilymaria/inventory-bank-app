<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Barang;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Fitur mobile khusus Admin — Scan Inbound (Barang Masuk).
 *
 * Alur: Admin scan barcode/QR pada kemasan barang (isi barcode = kode_barang
 * yang sudah ada, tidak ada kolom baru) → aplikasi mencari data barang →
 * Admin input jumlah barang masuk → stok bertambah & tercatat di riwayat_stok.
 */
class InboundApiController extends Controller
{
    // ── Helper: ambil auth_user dari request attributes ───
    private function authUser(Request $request)
    {
        return $request->attributes->get('auth_user');
    }

    // ── Helper: pastikan yang mengakses adalah Admin (role_id 1) ──
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
    // GET /api/admin/barang/{kode_barang}
    // Dipanggil setelah kamera berhasil scan barcode/QR barang.
    // ----------------------------------------------------------------
    public function cariBarang(Request $request, string $kode_barang)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $barang = DB::table('barang')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select(
                'barang.id',
                'barang.kode_barang',
                'barang.nama_barang',
                'barang.gambar',
                'barang.stok',
                'barang.stok_minimum',
                'barang.satuan',
                'barang.status_barang',
                'kategori_barang.nama_kategori'
            )
            ->where('barang.kode_barang', $kode_barang)
            ->first();

        if (!$barang) {
            return response()->json([
                'success' => false,
                'message' => "Barang dengan kode \"$kode_barang\" tidak ditemukan.",
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data'    => $barang,
        ]);
    }

    // ----------------------------------------------------------------
    // POST /api/admin/inbound
    // Body: kode_barang, jumlah, keterangan (opsional)
    // ----------------------------------------------------------------
    public function store(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $request->validate([
            'kode_barang' => 'required|string|exists:barang,kode_barang',
            'jumlah'      => 'required|integer|min:1',
            'keterangan'  => 'nullable|string|max:255',
        ], [
            'kode_barang.required' => 'Kode barang wajib diisi.',
            'kode_barang.exists'   => 'Barang tidak ditemukan.',
            'jumlah.required'      => 'Jumlah barang masuk wajib diisi.',
            'jumlah.integer'       => 'Jumlah harus berupa angka.',
            'jumlah.min'           => 'Jumlah minimal 1.',
        ]);

        $admin  = $this->authUser($request);
        $barang = DB::table('barang')->where('kode_barang', $request->kode_barang)->first();

        $stokSebelum = (int) $barang->stok;
        $stokSesudah = $stokSebelum + (int) $request->jumlah;
        $statusBaru  = Barang::hitungStatus($stokSesudah, (int) $barang->stok_minimum);

        DB::transaction(function () use (
            $request, $barang, $stokSebelum, $stokSesudah, $statusBaru, $admin
        ) {
            DB::table('barang')->where('id', $barang->id)->update([
                'stok'          => $stokSesudah,
                'status_barang' => $statusBaru,
                'updated_at'    => now(),
            ]);

            DB::table('riwayat_stok')->insert([
                'barang_id'       => $barang->id,
                'jenis_transaksi' => 'Masuk',
                'jumlah'          => $request->jumlah,
                'stok_sebelum'    => $stokSebelum,
                'stok_sesudah'    => $stokSesudah,
                'keterangan'      => $request->keterangan
                    ?: 'Stok masuk (scan barcode oleh ' . $admin->nama_lengkap . ')',
                'created_at'      => now(),
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => "Stok \"{$barang->nama_barang}\" berhasil ditambah "
                . "{$request->jumlah} {$barang->satuan}.",
            'data'    => [
                'kode_barang'   => $barang->kode_barang,
                'nama_barang'   => $barang->nama_barang,
                'satuan'        => $barang->satuan,
                'stok_sebelum'  => $stokSebelum,
                'stok_sesudah'  => $stokSesudah,
                'status_barang' => $statusBaru,
            ],
        ]);
    }

    // ----------------------------------------------------------------
    // GET /api/admin/inbound/riwayat
    // Riwayat inbound terbaru (untuk ditampilkan di halaman scan inbound)
    // ----------------------------------------------------------------
    public function riwayat(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $riwayat = DB::table('riwayat_stok')
            ->join('barang', 'riwayat_stok.barang_id', '=', 'barang.id')
            ->select(
                'riwayat_stok.*',
                'barang.kode_barang',
                'barang.nama_barang',
                'barang.satuan'
            )
            ->where('riwayat_stok.jenis_transaksi', 'Masuk')
            ->orderBy('riwayat_stok.id', 'desc')
            ->limit(15)
            ->get();

        return response()->json([
            'success' => true,
            'data'    => $riwayat,
        ]);
    }
}