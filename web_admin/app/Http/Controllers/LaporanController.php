<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LaporanController extends Controller
{
    // ----------------------------------------------------------------
    // INDEX — Halaman utama laporan (ringkasan + navigasi)
    // ----------------------------------------------------------------
    public function index()
    {
        // Ringkasan statistik untuk kartu laporan
        $stats = [
            // Barang
            'total_barang'     => DB::table('barang')->count(),
            'stok_menipis'     => DB::table('barang')->where('status_barang', 'Stok Menipis')->count(),
            'barang_habis'     => DB::table('barang')->where('status_barang', 'Habis')->count(),
            'total_stok'       => DB::table('barang')->sum('stok'),

            // Permintaan
            'total_permintaan' => DB::table('permintaan')->count(),
            'pending'          => DB::table('permintaan')->where('status_permintaan', 'Pending')->count(),
            'approved'         => DB::table('permintaan')->where('status_permintaan', 'Approved')->count(),
            'rejected'         => DB::table('permintaan')->where('status_permintaan', 'Rejected')->count(),
            'distributed'      => DB::table('permintaan')->where('status_permintaan', 'Distributed')->count(),

            // Distribusi
            'total_distribusi' => DB::table('distribusi')->count(),
            'dist_selesai'     => DB::table('distribusi')->where('status_distribusi', 'Selesai')->count(),

            // User
            'total_user'       => DB::table('users')->count(),
            'user_aktif'       => DB::table('users')->where('status_aktif', 'Aktif')->count(),

            // Riwayat stok bulan ini
            'stok_keluar_bulan_ini' => DB::table('riwayat_stok')
                ->where('jenis_transaksi', 'Keluar')
                ->whereMonth('created_at', now()->month)
                ->whereYear('created_at', now()->year)
                ->sum('jumlah'),
        ];

        return view('laporan.index', compact('stats'));
    }

    // ----------------------------------------------------------------
    // LAPORAN BARANG — Daftar seluruh barang & status stok
    // ----------------------------------------------------------------
    public function barang(Request $request)
    {
        $query = DB::table('barang')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select('barang.*', 'kategori_barang.nama_kategori');

        if ($request->filled('kategori')) {
            $query->where('barang.kategori_id', $request->kategori);
        }
        if ($request->filled('status')) {
            $query->where('barang.status_barang', $request->status);
        }
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('barang.nama_barang', 'like', "%{$search}%")
                  ->orWhere('barang.kode_barang', 'like', "%{$search}%");
            });
        }

        $barang    = $query->orderBy('kategori_barang.nama_kategori')
                           ->orderBy('barang.nama_barang')
                           ->paginate(15)->withQueryString();
        $kategoris = DB::table('kategori_barang')->orderBy('nama_kategori')->get();

        // Ringkasan stok per kategori
        $ringkasanKategori = DB::table('barang')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select(
                'kategori_barang.nama_kategori',
                DB::raw('COUNT(barang.id) as total_barang'),
                DB::raw('SUM(barang.stok) as total_stok'),
                DB::raw('SUM(CASE WHEN barang.status_barang = "Tersedia" THEN 1 ELSE 0 END) as tersedia'),
                DB::raw('SUM(CASE WHEN barang.status_barang = "Stok Menipis" THEN 1 ELSE 0 END) as menipis'),
                DB::raw('SUM(CASE WHEN barang.status_barang = "Habis" THEN 1 ELSE 0 END) as habis')
            )
            ->groupBy('kategori_barang.id', 'kategori_barang.nama_kategori')
            ->orderBy('kategori_barang.nama_kategori')
            ->get();

        return view('laporan.barang', compact('barang', 'kategoris', 'ringkasanKategori'));
    }

    // ----------------------------------------------------------------
    // LAPORAN PERMINTAAN — Rekap permintaan per periode
    // ----------------------------------------------------------------
    public function permintaan(Request $request)
    {
        // Default: bulan ini
        $bulan = $request->get('bulan', now()->format('Y-m'));

        $query = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->select('permintaan.*', 'users.nama_lengkap', 'users.bagian');

        // Filter periode bulan
        if ($bulan) {
            [$tahun, $bln] = explode('-', $bulan);
            $query->whereYear('permintaan.tanggal_permintaan', $tahun)
                  ->whereMonth('permintaan.tanggal_permintaan', $bln);
        }

        if ($request->filled('status')) {
            $query->where('permintaan.status_permintaan', $request->status);
        }

        $permintaan = $query->orderBy('permintaan.tanggal_permintaan', 'desc')
                            ->paginate(15)->withQueryString();

        // Ringkasan per status untuk periode ini
        $ringkasanStatus = DB::table('permintaan')
            ->select('status_permintaan', DB::raw('COUNT(*) as total'))
            ->when($bulan, function ($q) use ($bulan) {
                [$tahun, $bln] = explode('-', $bulan);
                $q->whereYear('tanggal_permintaan', $tahun)
                  ->whereMonth('tanggal_permintaan', $bln);
            })
            ->groupBy('status_permintaan')
            ->get()
            ->keyBy('status_permintaan');

        // Ringkasan per bagian
        $ringkasanBagian = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->select('users.bagian', DB::raw('COUNT(*) as total'))
            ->when($bulan, function ($q) use ($bulan) {
                [$tahun, $bln] = explode('-', $bulan);
                $q->whereYear('permintaan.tanggal_permintaan', $tahun)
                  ->whereMonth('permintaan.tanggal_permintaan', $bln);
            })
            ->groupBy('users.bagian')
            ->orderBy('total', 'desc')
            ->limit(5)
            ->get();

        return view('laporan.permintaan', compact(
            'permintaan', 'ringkasanStatus', 'ringkasanBagian', 'bulan'
        ));
    }

    // ----------------------------------------------------------------
    // LAPORAN DISTRIBUSI — Rekap distribusi per periode
    // ----------------------------------------------------------------
    public function distribusi(Request $request)
    {
        $bulan = $request->get('bulan', now()->format('Y-m'));

        $query = DB::table('distribusi')
            ->join('permintaan', 'distribusi.permintaan_id', '=', 'permintaan.id')
            ->join('users as pemohon', 'permintaan.user_id', '=', 'pemohon.id')
            ->join('users as admin', 'distribusi.admin_id', '=', 'admin.id')
            ->select(
                'distribusi.*',
                'permintaan.nomor_permintaan',
                'permintaan.prioritas',
                'pemohon.nama_lengkap as nama_pemohon',
                'pemohon.bagian',
                'admin.nama_lengkap as nama_admin'
            );

        if ($bulan) {
            [$tahun, $bln] = explode('-', $bulan);
            $query->whereYear('distribusi.tanggal_distribusi', $tahun)
                  ->whereMonth('distribusi.tanggal_distribusi', $bln);
        }

        $distribusi = $query->orderBy('distribusi.tanggal_distribusi', 'desc')
                            ->paginate(15)->withQueryString();

        // Total barang keluar periode ini
        $totalBarangKeluar = 0;
        if ($bulan) {
            [$tahun, $bln] = explode('-', $bulan);
            $totalBarangKeluar = DB::table('riwayat_stok')
                ->where('jenis_transaksi', 'Keluar')
                ->whereYear('created_at', $tahun)
                ->whereMonth('created_at', $bln)
                ->sum('jumlah');
        }

        return view('laporan.distribusi', compact('distribusi', 'bulan', 'totalBarangKeluar'));
    }

    // ----------------------------------------------------------------
    // LAPORAN STOK — Riwayat pergerakan stok per barang
    // ----------------------------------------------------------------
    public function stok(Request $request)
    {
        $query = DB::table('riwayat_stok')
            ->join('barang', 'riwayat_stok.barang_id', '=', 'barang.id')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select(
                'riwayat_stok.*',
                'barang.kode_barang',
                'barang.nama_barang',
                'barang.satuan',
                'kategori_barang.nama_kategori'
            );

        if ($request->filled('barang_id')) {
            $query->where('riwayat_stok.barang_id', $request->barang_id);
        }
        if ($request->filled('jenis')) {
            $query->where('riwayat_stok.jenis_transaksi', $request->jenis);
        }
        if ($request->filled('tanggal_dari')) {
            $query->whereDate('riwayat_stok.created_at', '>=', $request->tanggal_dari);
        }
        if ($request->filled('tanggal_sampai')) {
            $query->whereDate('riwayat_stok.created_at', '<=', $request->tanggal_sampai);
        }

        $riwayat   = $query->orderBy('riwayat_stok.id', 'desc')->paginate(15)->withQueryString();
        $semuaBarang = DB::table('barang')->orderBy('nama_barang')->get();

        // Ringkasan total masuk & keluar pada filter aktif
        $queryRingkasan = DB::table('riwayat_stok');
        if ($request->filled('barang_id')) {
            $queryRingkasan->where('barang_id', $request->barang_id);
        }
        if ($request->filled('tanggal_dari')) {
            $queryRingkasan->whereDate('created_at', '>=', $request->tanggal_dari);
        }
        if ($request->filled('tanggal_sampai')) {
            $queryRingkasan->whereDate('created_at', '<=', $request->tanggal_sampai);
        }

        $ringkasan = $queryRingkasan->select(
            DB::raw('SUM(CASE WHEN jenis_transaksi = "Masuk" THEN jumlah ELSE 0 END) as total_masuk'),
            DB::raw('SUM(CASE WHEN jenis_transaksi = "Keluar" THEN jumlah ELSE 0 END) as total_keluar'),
            DB::raw('COUNT(*) as total_transaksi')
        )->first();

        return view('laporan.stok', compact('riwayat', 'semuaBarang', 'ringkasan'));
    }
}