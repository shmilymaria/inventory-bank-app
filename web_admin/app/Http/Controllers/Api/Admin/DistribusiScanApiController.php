<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Barang;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Fitur mobile khusus Admin — Scan Checkout (validasi pengeluaran per item)
 * dan Scan Outbound (konfirmasi distribusi via QR dari HP User).
 *
 * Alur:
 * 1. Admin buka daftar permintaan "Siap Distribusi" (status Approved,
 *    belum ada record di tabel distribusi).
 * 2. Untuk tiap barang di permintaan, Admin scan barcode fisiknya satu-satu
 *    (Checkout) — dicocokkan otomatis dengan item permintaan, tersimpan
 *    permanen di checkout_scan_log.
 * 3. Setelah SEMUA item ter-checkout, Admin scan QR dari HP User (Outbound)
 *    — dicocokkan dengan qr_token yang di-generate saat approval — lalu
 *    dieksekusi: stok berkurang, riwayat_stok tercatat, status permintaan
 *    jadi Distributed, User dapat notifikasi. (Logic sama persis dengan
 *    DistribusiController::store() versi web, supaya konsisten.)
 */
class DistribusiScanApiController extends Controller
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
    // GET /api/admin/distribusi/siap
    // Daftar permintaan Approved yang belum didistribusikan, lengkap
    // dengan progres checkout (berapa item sudah discan).
    // ----------------------------------------------------------------
    public function siapDistribusi(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $daftar = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->leftJoin('distribusi', 'permintaan.id', '=', 'distribusi.permintaan_id')
            ->select(
                'permintaan.id',
                'permintaan.nomor_permintaan',
                'permintaan.prioritas',
                'permintaan.tanggal_permintaan',
                'users.nama_lengkap',
                'users.bagian'
            )
            ->where('permintaan.status_permintaan', 'Approved')
            ->whereNull('distribusi.id')
            ->orderBy('permintaan.id', 'asc')
            ->get();

        // Tambahkan progres checkout per permintaan
        $hasil = $daftar->map(function ($p) {
            $totalItem = DB::table('detail_permintaan')
                ->where('permintaan_id', $p->id)->count();
            $sudahDiscan = DB::table('checkout_scan_log')
                ->where('permintaan_id', $p->id)
                ->distinct('detail_permintaan_id')
                ->count('detail_permintaan_id');

            $p->total_item      = $totalItem;
            $p->item_sudah_scan = $sudahDiscan;
            $p->checkout_selesai = $totalItem > 0 && $sudahDiscan >= $totalItem;
            return $p;
        });

        return response()->json(['success' => true, 'data' => $hasil]);
    }

    // ----------------------------------------------------------------
    // GET /api/admin/distribusi/{permintaanId}
    // Detail permintaan + daftar item + status checkout tiap item.
    // ----------------------------------------------------------------
    public function detail(Request $request, int $permintaanId)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $permintaan = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->select('permintaan.*', 'users.nama_lengkap', 'users.bagian', 'users.jabatan')
            ->where('permintaan.id', $permintaanId)
            ->first();

        if (!$permintaan) {
            return response()->json([
                'success' => false,
                'message' => 'Permintaan tidak ditemukan.',
            ], 404);
        }

        $items = DB::table('detail_permintaan')
            ->join('barang', 'detail_permintaan.barang_id', '=', 'barang.id')
            ->select(
                'detail_permintaan.id as detail_id',
                'detail_permintaan.barang_id',
                'detail_permintaan.jumlah',
                'detail_permintaan.keterangan',
                'barang.kode_barang',
                'barang.nama_barang',
                'barang.satuan',
                'barang.stok as stok_tersedia'
            )
            ->where('detail_permintaan.permintaan_id', $permintaanId)
            ->get();

        // Tandai item yang sudah di-checkout
        $sudahScan = DB::table('checkout_scan_log')
            ->where('permintaan_id', $permintaanId)
            ->pluck('scanned_at', 'detail_permintaan_id');

        $items = $items->map(function ($item) use ($sudahScan) {
            $item->sudah_checkout = $sudahScan->has($item->detail_id);
            $item->waktu_checkout = $sudahScan->get($item->detail_id);
            return $item;
        });

        $semuaSudahCheckout = $items->every(fn($i) => $i->sudah_checkout);

        return response()->json([
            'success' => true,
            'data'    => [
                'permintaan'           => $permintaan,
                'items'                => $items,
                'semua_sudah_checkout' => $semuaSudahCheckout,
            ],
        ]);
    }

    // ----------------------------------------------------------------
    // POST /api/admin/distribusi/{permintaanId}/checkout
    // Body: kode_scan (hasil scan barcode barang fisik)
    // ----------------------------------------------------------------
    public function checkout(Request $request, int $permintaanId)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $request->validate([
            'kode_scan' => 'required|string',
        ]);

        $admin      = $this->authUser($request);
        $permintaan = DB::table('permintaan')
            ->where('id', $permintaanId)
            ->where('status_permintaan', 'Approved')
            ->first();

        if (!$permintaan) {
            return response()->json([
                'success' => false,
                'message' => 'Permintaan tidak ditemukan atau statusnya bukan Approved.',
            ], 404);
        }

        // Cari item permintaan ini yang barangnya cocok dengan kode yang discan
        $item = DB::table('detail_permintaan')
            ->join('barang', 'detail_permintaan.barang_id', '=', 'barang.id')
            ->select('detail_permintaan.id as detail_id', 'detail_permintaan.barang_id',
                     'detail_permintaan.jumlah', 'barang.nama_barang', 'barang.satuan',
                     'barang.kode_barang')
            ->where('detail_permintaan.permintaan_id', $permintaanId)
            ->where('barang.kode_barang', $request->kode_scan)
            ->first();

        if (!$item) {
            return response()->json([
                'success' => false,
                'message' => "Barang dengan kode \"{$request->kode_scan}\" tidak termasuk "
                    . "dalam permintaan ini.",
            ], 422);
        }

        // Cek apakah item ini sudah pernah discan sebelumnya (idempotent)
        $sudahAda = DB::table('checkout_scan_log')
            ->where('detail_permintaan_id', $item->detail_id)
            ->exists();

        if ($sudahAda) {
            return response()->json([
                'success' => true,
                'message' => "\"{$item->nama_barang}\" sudah dicek sebelumnya.",
                'data'    => ['detail_id' => $item->detail_id, 'sudah_ada' => true],
            ]);
        }

        DB::table('checkout_scan_log')->insert([
            'permintaan_id'         => $permintaanId,
            'detail_permintaan_id'  => $item->detail_id,
            'barang_id'             => $item->barang_id,
            'admin_id'              => $admin->id,
            'kode_scan'             => $request->kode_scan,
            'status_scan'           => 'Cocok',
            'scanned_at'            => now(),
        ]);

        // Hitung progres terbaru
        $totalItem   = DB::table('detail_permintaan')->where('permintaan_id', $permintaanId)->count();
        $sudahDiscan = DB::table('checkout_scan_log')
            ->where('permintaan_id', $permintaanId)
            ->distinct('detail_permintaan_id')
            ->count('detail_permintaan_id');

        return response()->json([
            'success' => true,
            'message' => "\"{$item->nama_barang}\" ({$item->jumlah} {$item->satuan}) berhasil dicek.",
            'data'    => [
                'detail_id'      => $item->detail_id,
                'sudah_ada'      => false,
                'progres'        => "$sudahDiscan/$totalItem",
                'semua_selesai'  => $sudahDiscan >= $totalItem,
            ],
        ]);
    }

    // ----------------------------------------------------------------
    // POST /api/admin/distribusi/{permintaanId}/outbound
    // Body: qr_code (hasil scan QR dari HP User)
    // ----------------------------------------------------------------
    public function outbound(Request $request, int $permintaanId)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $request->validate([
            'qr_code' => 'required|string',
        ]);

        $admin      = $this->authUser($request);
        $permintaan = DB::table('permintaan')
            ->where('id', $permintaanId)
            ->where('status_permintaan', 'Approved')
            ->first();

        if (!$permintaan) {
            return response()->json([
                'success' => false,
                'message' => 'Permintaan tidak ditemukan, sudah didistribusikan, atau belum disetujui.',
            ], 404);
        }

        // Pastikan belum pernah didistribusikan (double-check race condition)
        if (DB::table('distribusi')->where('permintaan_id', $permintaanId)->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Permintaan ini sudah pernah didistribusikan.',
            ], 422);
        }

        // Pastikan QR valid & memang milik permintaan ini
        if (empty($permintaan->qr_token) || $permintaan->qr_token !== $request->qr_code) {
            return response()->json([
                'success' => false,
                'message' => 'QR tidak valid atau bukan milik permintaan ini.',
            ], 422);
        }

        // Pastikan semua item sudah melalui tahap Checkout
        $detailItems = DB::table('detail_permintaan')
            ->join('barang', 'detail_permintaan.barang_id', '=', 'barang.id')
            ->select('detail_permintaan.*', 'barang.stok', 'barang.stok_minimum', 'barang.nama_barang')
            ->where('detail_permintaan.permintaan_id', $permintaanId)
            ->get();

        $totalItem   = $detailItems->count();
        $sudahDiscan = DB::table('checkout_scan_log')
            ->where('permintaan_id', $permintaanId)
            ->distinct('detail_permintaan_id')
            ->count('detail_permintaan_id');

        if ($sudahDiscan < $totalItem) {
            return response()->json([
                'success' => false,
                'message' => "Masih ada " . ($totalItem - $sudahDiscan)
                    . " barang yang belum di-scan Checkout.",
            ], 422);
        }

        // Validasi stok masih mencukupi (bisa saja berubah sejak approval)
        foreach ($detailItems as $item) {
            if ($item->stok < $item->jumlah) {
                return response()->json([
                    'success' => false,
                    'message' => "Stok \"{$item->nama_barang}\" tidak mencukupi. "
                        . "Tersedia: {$item->stok}, Dibutuhkan: {$item->jumlah}.",
                ], 422);
            }
        }

        // Eksekusi distribusi — logic sama dengan DistribusiController::store()
        DB::transaction(function () use ($permintaanId, $permintaan, $detailItems, $admin) {

            DB::table('distribusi')->insert([
                'permintaan_id'      => $permintaanId,
                'admin_id'           => $admin->id,
                'tanggal_distribusi' => now(),
                'status_distribusi'  => 'Selesai',
                'catatan_distribusi' => 'Dikonfirmasi via scan QR (Outbound - Mobile)',
            ]);

            foreach ($detailItems as $item) {
                $stokSebelum = $item->stok;
                $stokSesudah = $stokSebelum - $item->jumlah;
                $statusBaru  = Barang::hitungStatus($stokSesudah, $item->stok_minimum);

                DB::table('barang')->where('id', $item->barang_id)->update([
                    'stok'          => $stokSesudah,
                    'status_barang' => $statusBaru,
                    'updated_at'    => now(),
                ]);

                DB::table('riwayat_stok')->insert([
                    'barang_id'       => $item->barang_id,
                    'jenis_transaksi' => 'Keluar',
                    'jumlah'          => $item->jumlah,
                    'stok_sebelum'    => $stokSebelum,
                    'stok_sesudah'    => $stokSesudah,
                    'keterangan'      => 'Distribusi permintaan ' . $permintaan->nomor_permintaan,
                    'created_at'      => now(),
                ]);
            }

            DB::table('permintaan')->where('id', $permintaanId)->update([
                'status_permintaan' => 'Distributed',
            ]);

            DB::table('notifikasi')->insert([
                'user_id'     => $permintaan->user_id,
                'judul'       => 'Barang Telah Didistribusikan',
                'pesan'       => 'Permintaan ' . $permintaan->nomor_permintaan .
                                 ' telah selesai diproses dan barang sudah didistribusikan.',
                'status_baca' => 'Belum Dibaca',
                'created_at'  => now(),
            ]);
        });

        return response()->json([
            'success' => true,
            'message' => 'Outbound berhasil dikonfirmasi. Distribusi selesai & stok telah diperbarui.',
        ]);
    }

    // ----------------------------------------------------------------
    // GET /api/admin/distribusi/riwayat
    // Riwayat gabungan Checkout + Outbound terbaru (untuk ditampilkan
    // di halaman daftar distribusi, sama seperti riwayat di Scan Inbound).
    // ----------------------------------------------------------------
    public function riwayat(Request $request)
    {
        if ($blok = $this->pastikanAdmin($request)) return $blok;

        $checkoutLog = DB::table('checkout_scan_log')
            ->join('permintaan', 'checkout_scan_log.permintaan_id', '=', 'permintaan.id')
            ->join('barang', 'checkout_scan_log.barang_id', '=', 'barang.id')
            ->join('users', 'checkout_scan_log.admin_id', '=', 'users.id')
            ->select(
                DB::raw("'Checkout' as tipe"),
                'permintaan.nomor_permintaan',
                'barang.nama_barang as keterangan',
                'users.nama_lengkap as nama_admin',
                'checkout_scan_log.scanned_at as waktu'
            )
            ->orderBy('checkout_scan_log.scanned_at', 'desc')
            ->limit(15)
            ->get();

        $outboundLog = DB::table('distribusi')
            ->join('permintaan', 'distribusi.permintaan_id', '=', 'permintaan.id')
            ->join('users', 'distribusi.admin_id', '=', 'users.id')
            ->select(
                DB::raw("'Outbound' as tipe"),
                'permintaan.nomor_permintaan',
                DB::raw("'Distribusi selesai — barang diserahkan ke User' as keterangan"),
                'users.nama_lengkap as nama_admin',
                'distribusi.tanggal_distribusi as waktu'
            )
            ->orderBy('distribusi.tanggal_distribusi', 'desc')
            ->limit(15)
            ->get();

        // Gabungkan kedua jenis riwayat, urutkan berdasarkan waktu terbaru
        $gabungan = $checkoutLog->concat($outboundLog)
            ->sortByDesc('waktu')
            ->take(20)
            ->values();

        return response()->json([
            'success' => true,
            'data'    => $gabungan,
        ]);
    }
}