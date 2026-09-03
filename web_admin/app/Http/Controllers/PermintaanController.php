<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PermintaanController extends Controller
{
    // ----------------------------------------------------------------
    // INDEX — Daftar seluruh permintaan
    // ----------------------------------------------------------------
    public function index(Request $request)
    {
        $query = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->select(
                'permintaan.*',
                'users.nama_lengkap',
                'users.bagian'
            );

        // Filter pencarian
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('permintaan.nomor_permintaan', 'like', "%{$search}%")
                  ->orWhere('users.nama_lengkap', 'like', "%{$search}%")
                  ->orWhere('users.bagian', 'like', "%{$search}%");
            });
        }

        // Filter status
        if ($request->filled('status')) {
            $query->where('permintaan.status_permintaan', $request->status);
        }

        // Filter prioritas
        if ($request->filled('prioritas')) {
            $query->where('permintaan.prioritas', $request->prioritas);
        }

        // Filter tanggal
        if ($request->filled('tanggal_dari')) {
            $query->whereDate('permintaan.tanggal_permintaan', '>=', $request->tanggal_dari);
        }
        if ($request->filled('tanggal_sampai')) {
            $query->whereDate('permintaan.tanggal_permintaan', '<=', $request->tanggal_sampai);
        }

        $permintaan = $query->orderBy('permintaan.id', 'desc')
                            ->paginate(10)->withQueryString();

        // Hitung statistik
        $stats = [
            'total'       => DB::table('permintaan')->count(),
            'pending'     => DB::table('permintaan')->where('status_permintaan', 'Pending')->count(),
            'approved'    => DB::table('permintaan')->where('status_permintaan', 'Approved')->count(),
            'rejected'    => DB::table('permintaan')->where('status_permintaan', 'Rejected')->count(),
            'revision'    => DB::table('permintaan')->where('status_permintaan', 'Revision')->count(),
            'distributed' => DB::table('permintaan')->where('status_permintaan', 'Distributed')->count(),
        ];

        return view('permintaan.index', compact('permintaan', 'stats'));
    }

    // ----------------------------------------------------------------
    // SHOW — Detail permintaan + item + approval
    // ----------------------------------------------------------------
    public function show(int $id)
    {
        // Data permintaan utama
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
            ->firstOrFail();

        // Detail item barang yang diminta
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
            ->where('detail_permintaan.permintaan_id', $id)
            ->get();

        // Data approval jika ada
        $approval = DB::table('approval')
            ->join('users', 'approval.pimpinan_id', '=', 'users.id')
            ->select('approval.*', 'users.nama_lengkap as nama_pimpinan', 'users.jabatan as jabatan_pimpinan')
            ->where('approval.permintaan_id', $id)
            ->latest('approval.tanggal_approval')
            ->first();

        // Data distribusi jika ada
        $distribusi = DB::table('distribusi')
            ->join('users', 'distribusi.admin_id', '=', 'users.id')
            ->select('distribusi.*', 'users.nama_lengkap as nama_admin')
            ->where('distribusi.permintaan_id', $id)
            ->first();

        return view('permintaan.show', compact(
            'permintaan', 'detailItems', 'approval', 'distribusi'
        ));
    }
}