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

    // ----------------------------------------------------------------
    // GET /api/admin/kategori
    // Daftar kategori untuk dropdown form "Tambah Barang Baru"
    // ----------------------------------------------------------------
    public function daftarKategori(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $kategori = DB::table('kategori_barang')
            ->select('id', 'nama_kategori')
            ->orderBy('nama_kategori')
            ->get();

        return response()->json(['success' => true, 'data' => $kategori]);
    }

    // ----------------------------------------------------------------
    // GET /api/admin/barang/generate-kode
    // Generate kode unik (format GEN-0001, GEN-0002, dst) untuk barang
    // yang belum punya barcode fisik (misal produk keluaran bank sendiri:
    // formulir, buku cek, dll). Kode ini nanti dirender jadi barcode
    // Code128 di sisi mobile supaya bisa di-screenshot/print & discan lagi.
    // ----------------------------------------------------------------
    public function generateKode(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $terakhir = DB::table('barang')
            ->where('kode_barang', 'like', 'GEN-%')
            ->orderByRaw('CAST(SUBSTRING(kode_barang, 5) AS UNSIGNED) desc')
            ->value('kode_barang');

        $nomorBaru = 1;
        if ($terakhir) {
            $angka = (int) substr($terakhir, 4);
            $nomorBaru = $angka + 1;
        }

        // Pastikan benar-benar unik (jaga-jaga kalau ada input manual bentrok)
        do {
            $kodeBaru = 'GEN-' . str_pad($nomorBaru, 4, '0', STR_PAD_LEFT);
            $sudahAda = DB::table('barang')->where('kode_barang', $kodeBaru)->exists();
            $nomorBaru++;
        } while ($sudahAda);

        return response()->json(['success' => true, 'data' => ['kode_barang' => $kodeBaru]]);
    }

    // ----------------------------------------------------------------
    // POST /api/admin/barang
    // Tambah barang baru langsung dari mobile (dipicu saat scan tidak
    // ditemukan, atau lewat tombol "+ Tambah Barang Baru" di katalog).
    // Stok awal selalu 0 — pengisian stok tetap lewat alur tally-scan
    // Inbound seperti biasa setelah barang ini dibuat.
    // ----------------------------------------------------------------
    public function tambahBarang(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $request->validate([
            'kategori_id'  => 'required|integer|exists:kategori_barang,id',
            'nama_barang'  => 'required|string|max:150',
            'kode_barang'  => 'required|string|max:50|unique:barang,kode_barang',
            'satuan'       => 'required|string|max:20',
            'stok_minimum' => 'required|integer|min:0',
            'deskripsi'    => 'nullable|string',
        ], [
            'kategori_id.required'  => 'Kategori wajib dipilih.',
            'nama_barang.required'  => 'Nama barang wajib diisi.',
            'kode_barang.required'  => 'Kode/barcode barang wajib diisi.',
            'kode_barang.unique'    => 'Kode/barcode ini sudah terdaftar untuk barang lain.',
            'satuan.required'       => 'Satuan wajib diisi.',
            'stok_minimum.required' => 'Stok minimum wajib diisi.',
        ]);

        $barangId = DB::table('barang')->insertGetId([
            'kategori_id'        => $request->kategori_id,
            'kode_barang'        => trim($request->kode_barang),
            'nama_barang'        => $request->nama_barang,
            'stok'               => 0,
            'stok_minimum'       => $request->stok_minimum,
            'satuan'             => $request->satuan,
            'deskripsi'          => $request->deskripsi,
            'status_barang'      => Barang::hitungStatus(0, (int) $request->stok_minimum),
            'created_at'         => now(),
            'updated_at'         => now(),
        ]);

        $barang = DB::table('barang')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select('barang.*', 'kategori_barang.nama_kategori')
            ->where('barang.id', $barangId)
            ->first();

        return response()->json([
            'success' => true,
            'message' => 'Barang baru berhasil ditambahkan. Silakan lanjut scan untuk mengisi stok.',
            'data'    => $barang,
        ]);
    }
}