<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Fitur mobile khusus Admin — Scan Audit / Stock Opname.
 *
 * Alur: Admin mulai sesi opname → scan barang satu-satu → input stok
 * fisik hasil hitung manual → sistem hitung selisih (stok fisik - stok
 * sistem) dan CATAT SAJA sebagai laporan (tidak mengubah stok barang
 * secara otomatis, sesuai keputusan — penyesuaian dilakukan manual oleh
 * Admin lewat menu Edit Barang di Web kalau memang diperlukan).
 */
class OpnameApiController extends Controller
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
    // GET /api/admin/opname/aktif
    // Cek apakah Admin ini punya sesi opname yang masih berlangsung
    // (supaya kalau app ditutup di tengah jalan, bisa dilanjutkan lagi).
    // ----------------------------------------------------------------
    public function aktif(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;
        $admin = $this->authUser($request);

        $sesi = DB::table('stock_opname')
            ->where('admin_id', $admin->id)
            ->where('status_opname', 'Berlangsung')
            ->latest('tanggal_mulai')
            ->first();

        if (!$sesi) {
            return response()->json(['success' => true, 'data' => null]);
        }

        return response()->json([
            'success' => true,
            'data'    => $this->buildDetail($sesi->id),
        ]);
    }

    // ----------------------------------------------------------------
    // POST /api/admin/opname/mulai
    // Mulai sesi baru (atau lanjutkan yang masih berlangsung kalau ada).
    // ----------------------------------------------------------------
    public function mulai(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;
        $admin = $this->authUser($request);

        $sesiAktif = DB::table('stock_opname')
            ->where('admin_id', $admin->id)
            ->where('status_opname', 'Berlangsung')
            ->latest('tanggal_mulai')
            ->first();

        if ($sesiAktif) {
            return response()->json([
                'success' => true,
                'message' => 'Melanjutkan sesi opname yang sedang berlangsung.',
                'data'    => $this->buildDetail($sesiAktif->id),
            ]);
        }

        $opnameId = DB::table('stock_opname')->insertGetId([
            'admin_id'       => $admin->id,
            'tanggal_mulai'  => now(),
            'status_opname'  => 'Berlangsung',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Sesi opname baru dimulai.',
            'data'    => $this->buildDetail($opnameId),
        ]);
    }

    // ----------------------------------------------------------------
    // GET /api/admin/opname/barang/{kode_barang}?opname_id=X
    // Cari barang by kode (hasil scan) + cek apakah sudah pernah discan
    // di sesi ini (untuk prefill stok fisik kalau scan ulang).
    // ----------------------------------------------------------------
    public function cariBarang(Request $request, string $kode_barang)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $barang = DB::table('barang')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select(
                'barang.id', 'barang.kode_barang', 'barang.nama_barang',
                'barang.gambar', 'barang.stok', 'barang.satuan',
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

        $opnameId = $request->query('opname_id');
        $existing = null;
        if ($opnameId) {
            $existing = DB::table('stock_opname_detail')
                ->where('opname_id', $opnameId)
                ->where('barang_id', $barang->id)
                ->first();
        }

        return response()->json([
            'success' => true,
            'data'    => [
                'barang'          => $barang,
                'sudah_discan'    => $existing !== null,
                'stok_fisik_lama' => $existing->stok_fisik ?? null,
                'keterangan_lama' => $existing->keterangan ?? null,
            ],
        ]);
    }

    // ----------------------------------------------------------------
    // POST /api/admin/opname/{opnameId}/scan
    // Body: kode_barang, stok_fisik, keterangan (opsional)
    // ----------------------------------------------------------------
    public function scan(Request $request, int $opnameId)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $request->validate([
            'kode_barang' => 'required|string|exists:barang,kode_barang',
            'stok_fisik'  => 'required|integer|min:0',
            'keterangan'  => 'nullable|string|max:255',
        ], [
            'kode_barang.exists' => 'Barang tidak ditemukan.',
            'stok_fisik.required'=> 'Stok fisik wajib diisi.',
            'stok_fisik.min'     => 'Stok fisik tidak boleh negatif.',
        ]);

        $sesi = DB::table('stock_opname')
            ->where('id', $opnameId)
            ->where('status_opname', 'Berlangsung')
            ->first();

        if (!$sesi) {
            return response()->json([
                'success' => false,
                'message' => 'Sesi opname tidak ditemukan atau sudah diselesaikan.',
            ], 404);
        }

        $barang = DB::table('barang')->where('kode_barang', $request->kode_barang)->first();

        $stokSistem = (int) $barang->stok;
        $stokFisik  = (int) $request->stok_fisik;
        $selisih    = $stokFisik - $stokSistem;

        // Upsert — kalau barang ini sudah pernah discan di sesi yg sama,
        // update saja (scan ulang untuk koreksi hitungan).
        DB::table('stock_opname_detail')->updateOrInsert(
            ['opname_id' => $opnameId, 'barang_id' => $barang->id],
            [
                'stok_sistem' => $stokSistem,
                'stok_fisik'  => $stokFisik,
                'selisih'     => $selisih,
                'keterangan'  => $request->keterangan,
                'scanned_at'  => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => $selisih === 0
                ? "\"{$barang->nama_barang}\" cocok — stok sesuai."
                : "\"{$barang->nama_barang}\" ada selisih "
                    . ($selisih > 0 ? "+$selisih" : "$selisih") . " {$barang->satuan}.",
            'data' => [
                'nama_barang' => $barang->nama_barang,
                'stok_sistem' => $stokSistem,
                'stok_fisik'  => $stokFisik,
                'selisih'     => $selisih,
            ],
        ]);
    }

    // ----------------------------------------------------------------
    // POST /api/admin/opname/{opnameId}/selesai
    // ----------------------------------------------------------------
    public function selesai(Request $request, int $opnameId)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $request->validate([
            'catatan' => 'nullable|string|max:500',
        ]);

        $sesi = DB::table('stock_opname')
            ->where('id', $opnameId)
            ->where('status_opname', 'Berlangsung')
            ->first();

        if (!$sesi) {
            return response()->json([
                'success' => false,
                'message' => 'Sesi opname tidak ditemukan atau sudah diselesaikan.',
            ], 404);
        }

        DB::table('stock_opname')->where('id', $opnameId)->update([
            'status_opname'   => 'Selesai',
            'tanggal_selesai' => now(),
            'catatan'         => $request->catatan,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Sesi opname berhasil diselesaikan.',
            'data'    => $this->buildDetail($opnameId),
        ]);
    }

    // ----------------------------------------------------------------
    // GET /api/admin/opname/riwayat
    // Daftar sesi opname yang sudah Selesai.
    // ----------------------------------------------------------------
    public function riwayat(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $riwayat = DB::table('stock_opname')
            ->join('users', 'stock_opname.admin_id', '=', 'users.id')
            ->select(
                'stock_opname.id', 'stock_opname.tanggal_mulai',
                'stock_opname.tanggal_selesai', 'users.nama_lengkap as nama_admin'
            )
            ->where('status_opname', 'Selesai')
            ->orderBy('tanggal_selesai', 'desc')
            ->limit(15)
            ->get()
            ->map(function ($s) {
                $s->total_item = DB::table('stock_opname_detail')
                    ->where('opname_id', $s->id)->count();
                $s->total_selisih = DB::table('stock_opname_detail')
                    ->where('opname_id', $s->id)->where('selisih', '!=', 0)->count();
                return $s;
            });

        return response()->json(['success' => true, 'data' => $riwayat]);
    }

    // ----------------------------------------------------------------
    // GET /api/admin/opname/{opnameId}
    // Detail 1 sesi (dipakai untuk sesi aktif maupun riwayat selesai)
    // ----------------------------------------------------------------
    public function detail(Request $request, int $opnameId)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $data = $this->buildDetail($opnameId);
        if (!$data) {
            return response()->json([
                'success' => false,
                'message' => 'Sesi opname tidak ditemukan.',
            ], 404);
        }

        return response()->json(['success' => true, 'data' => $data]);
    }

    // ── Helper: susun detail lengkap 1 sesi opname ────────────
    private function buildDetail(int $opnameId): ?array
    {
        $sesi = DB::table('stock_opname')
            ->join('users', 'stock_opname.admin_id', '=', 'users.id')
            ->select('stock_opname.*', 'users.nama_lengkap as nama_admin')
            ->where('stock_opname.id', $opnameId)
            ->first();

        if (!$sesi) return null;

        $items = DB::table('stock_opname_detail')
            ->join('barang', 'stock_opname_detail.barang_id', '=', 'barang.id')
            ->select(
                'stock_opname_detail.*',
                'barang.kode_barang', 'barang.nama_barang', 'barang.satuan'
            )
            ->where('opname_id', $opnameId)
            ->orderBy('stock_opname_detail.scanned_at', 'desc')
            ->get();

        return [
            'sesi'           => $sesi,
            'items'          => $items,
            'total_item'     => $items->count(),
            'total_selisih'  => $items->where('selisih', '!=', 0)->count(),
        ];
    }
}