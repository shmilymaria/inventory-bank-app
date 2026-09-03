<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index()
    {
        // Barang
        $totalBarang = DB::table('barang')->count();
        $totalStok = DB::table('barang')->sum('stok');

        $stokMenipis = DB::table('barang')
            ->where('status_barang', 'Stok Menipis')
            ->count();

        $barangHabis = DB::table('barang')
            ->where('status_barang', 'Habis')
            ->count();

        // Permintaan
        $pendingRequest = DB::table('permintaan')
            ->where('status_permintaan', 'Pending')
            ->count();

        $approvedRequest = DB::table('permintaan')
            ->where('status_permintaan', 'Approved')
            ->count();

        $rejectedRequest = DB::table('permintaan')
            ->where('status_permintaan', 'Rejected')
            ->count();

        // Approval
        $approvalApproved = DB::table('approval')
            ->where('keputusan', 'Approved')
            ->count();

        $approvalRejected = DB::table('approval')
            ->where('keputusan', 'Rejected')
            ->count();

        // Distribusi
        $distribusiDiproses = DB::table('distribusi')
            ->where('status_distribusi', 'Diproses')
            ->count();

        $distribusiSelesai = DB::table('distribusi')
            ->where('status_distribusi', 'Selesai')
            ->count();

        // Aktivitas Permintaan Terbaru
        $recentRequests = DB::table('permintaan')
            ->join('users', 'permintaan.user_id', '=', 'users.id')
            ->select(
                'permintaan.nomor_permintaan',
                'users.nama_lengkap',
                'permintaan.status_permintaan',
                'permintaan.tanggal_permintaan'
            )
            ->orderBy('permintaan.id', 'desc')
            ->limit(5)
            ->get();

        return view('dashboard', compact(
            'totalBarang',
            'totalStok',
            'stokMenipis',
            'barangHabis',
            'pendingRequest',
            'approvedRequest',
            'rejectedRequest',
            'approvalApproved',
            'approvalRejected',
            'distribusiDiproses',
            'distribusiSelesai',
            'recentRequests'
        ));
    }
}