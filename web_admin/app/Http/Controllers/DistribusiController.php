<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Barang;

class DistribusiController extends Controller
{
    // ----------------------------------------------------------------
    // INDEX — Daftar permintaan yang siap didistribusikan & riwayat
    // ----------------------------------------------------------------
    public function index(Request $request)
    {
        // Permintaan berstatus Approved yang belum didistribusikan
        $siapDistribusi = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->leftJoin('distribusi', 'permintaan.id', '=', 'distribusi.permintaan_id')
            ->select('permintaan.*', 'users.nama_lengkap', 'users.bagian')
            ->where('permintaan.status_permintaan', 'Approved')
            ->whereNull('distribusi.id')
            ->orderBy('permintaan.id', 'asc')
            ->get();

        // Riwayat distribusi (semua yang sudah diproses)
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

        // Filter status distribusi
        if ($request->filled('status')) {
            $query->where('distribusi.status_distribusi', $request->status);
        }

        // Filter pencarian
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('permintaan.nomor_permintaan', 'like', "%{$search}%")
                  ->orWhere('pemohon.nama_lengkap', 'like', "%{$search}%");
            });
        }

        $riwayatDistribusi = $query->orderBy('distribusi.id', 'desc')
                                   ->paginate(10)->withQueryString();

        // Statistik
        $stats = [
            'siap'     => $siapDistribusi->count(),
            'diproses' => DB::table('distribusi')->where('status_distribusi', 'Diproses')->count(),
            'selesai'  => DB::table('distribusi')->where('status_distribusi', 'Selesai')->count(),
        ];

        return view('distribusi.index', compact('siapDistribusi', 'riwayatDistribusi', 'stats'));
    }

    // ----------------------------------------------------------------
    // SHOW — Form proses distribusi untuk permintaan tertentu
    // ----------------------------------------------------------------
    public function show(int $permintaanId)
    {
        // Ambil data permintaan
        $permintaan = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->select('permintaan.*', 'users.nama_lengkap', 'users.bagian', 'users.jabatan')
            ->where('permintaan.id', $permintaanId)
            ->where('permintaan.status_permintaan', 'Approved')
            ->firstOrFail();

        // Ambil detail item barang
        $detailItems = DB::table('detail_permintaan')
            ->join('barang', 'detail_permintaan.barang_id', '=', 'barang.id')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select(
                'detail_permintaan.*',
                'barang.kode_barang',
                'barang.nama_barang',
                'barang.satuan',
                'barang.stok as stok_tersedia',
                'barang.status_barang',
                'kategori_barang.nama_kategori'
            )
            ->where('detail_permintaan.permintaan_id', $permintaanId)
            ->get();

        // Ambil data approval
        $approval = DB::table('approval')
            ->join('users', 'approval.pimpinan_id', '=', 'users.id')
            ->select('approval.*', 'users.nama_lengkap as nama_pimpinan')
            ->where('approval.permintaan_id', $permintaanId)
            ->latest('approval.tanggal_approval')
            ->first();

        // Cek apakah stok semua item mencukupi
        $stokCukup = $detailItems->every(fn($item) => $item->stok_tersedia >= $item->jumlah);

        return view('distribusi.show', compact(
            'permintaan', 'detailItems', 'approval', 'stokCukup'
        ));
    }

    // ----------------------------------------------------------------
    // STORE — Simpan & eksekusi distribusi
    // ----------------------------------------------------------------
    public function store(Request $request, int $permintaanId)
    {
        $request->validate([
            'catatan_distribusi' => 'nullable|string|max:500',
        ]);

        // Ambil data permintaan — pastikan statusnya Approved
        $permintaan = DB::table('permintaan')
            ->where('id', $permintaanId)
            ->where('status_permintaan', 'Approved')
            ->firstOrFail();

        // Pastikan belum pernah didistribusikan
        $sudahAda = DB::table('distribusi')
            ->where('permintaan_id', $permintaanId)
            ->exists();

        if ($sudahAda) {
            return redirect()->route('distribusi.index')
                ->with('error', 'Permintaan ini sudah pernah didistribusikan.');
        }

        // Ambil detail item
        $detailItems = DB::table('detail_permintaan')
            ->join('barang', 'detail_permintaan.barang_id', '=', 'barang.id')
            ->select('detail_permintaan.*', 'barang.stok', 'barang.stok_minimum', 'barang.nama_barang')
            ->where('detail_permintaan.permintaan_id', $permintaanId)
            ->get();

        // Validasi stok semua item sebelum eksekusi
        foreach ($detailItems as $item) {
            if ($item->stok < $item->jumlah) {
                return redirect()->route('distribusi.show', $permintaanId)
                    ->with('error', "Stok barang \"{$item->nama_barang}\" tidak mencukupi. 
                        Tersedia: {$item->stok}, Dibutuhkan: {$item->jumlah}.");
            }
        }

        // Eksekusi dalam transaksi database
        DB::transaction(function () use ($request, $permintaanId, $permintaan, $detailItems) {

            $adminId = session('user_id');

            // 1. Simpan record distribusi
            DB::table('distribusi')->insert([
                'permintaan_id'      => $permintaanId,
                'admin_id'           => $adminId,
                'tanggal_distribusi' => now(),
                'status_distribusi'  => 'Selesai',
                'catatan_distribusi' => $request->catatan_distribusi,
            ]);

            // 2. Kurangi stok setiap barang & catat riwayat stok
            foreach ($detailItems as $item) {
                $stokSebelum = $item->stok;
                $stokSesudah = $stokSebelum - $item->jumlah;
                $statusBaru  = Barang::hitungStatus($stokSesudah, $item->stok_minimum);

                // Update stok & status barang
                DB::table('barang')->where('id', $item->barang_id)->update([
                    'stok'          => $stokSesudah,
                    'status_barang' => $statusBaru,
                    'updated_at'    => now(),
                ]);

                // Catat riwayat stok
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

            // 3. Update status permintaan menjadi Distributed
            DB::table('permintaan')->where('id', $permintaanId)->update([
                'status_permintaan' => 'Distributed',
            ]);

            // 4. Kirim notifikasi ke pemohon
            DB::table('notifikasi')->insert([
                'user_id'     => $permintaan->user_id,
                'judul'       => 'Barang Telah Didistribusikan',
                'pesan'       => 'Permintaan ' . $permintaan->nomor_permintaan .
                                 ' telah selesai diproses dan barang sudah didistribusikan.',
                'status_baca' => 'Belum Dibaca',
                'created_at'  => now(),
            ]);

        });

        return redirect()->route('distribusi.index')
            ->with('success', 'Distribusi berhasil diproses. Stok barang telah diperbarui.');
    }

    // ----------------------------------------------------------------
    // DETAIL — Lihat detail riwayat distribusi yang sudah selesai
    // ----------------------------------------------------------------
    public function detail(int $distribusiId)
    {
        $distribusi = DB::table('distribusi')
            ->join('permintaan', 'distribusi.permintaan_id', '=', 'permintaan.id')
            ->join('users as pemohon', 'permintaan.user_id', '=', 'pemohon.id')
            ->join('users as admin', 'distribusi.admin_id', '=', 'admin.id')
            ->select(
                'distribusi.*',
                'permintaan.nomor_permintaan',
                'permintaan.prioritas',
                'permintaan.catatan as catatan_permintaan',
                'permintaan.tanggal_permintaan',
                'pemohon.nama_lengkap as nama_pemohon',
                'pemohon.bagian',
                'pemohon.jabatan',
                'admin.nama_lengkap as nama_admin'
            )
            ->where('distribusi.id', $distribusiId)
            ->firstOrFail();

        $detailItems = DB::table('detail_permintaan')
            ->join('barang', 'detail_permintaan.barang_id', '=', 'barang.id')
            ->join('kategori_barang', 'barang.kategori_id', '=', 'kategori_barang.id')
            ->select(
                'detail_permintaan.*',
                'barang.kode_barang',
                'barang.nama_barang',
                'barang.satuan',
                'barang.stok as stok_sekarang',
                'kategori_barang.nama_kategori'
            )
            ->where('detail_permintaan.permintaan_id', $distribusi->permintaan_id)
            ->get();

        $approval = DB::table('approval')
            ->join('users', 'approval.pimpinan_id', '=', 'users.id')
            ->select('approval.*', 'users.nama_lengkap as nama_pimpinan')
            ->where('approval.permintaan_id', $distribusi->permintaan_id)
            ->latest('approval.tanggal_approval')
            ->first();

        return view('distribusi.detail', compact('distribusi', 'detailItems', 'approval'));
    }
}