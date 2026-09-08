<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class ApiController extends Controller
{
    // ── Helper: ambil auth_user dari request attributes ───
    private function authUser(Request $request)
    {
        return $request->attributes->get('auth_user');
    }

    // ----------------------------------------------------------------
    // POST /api/login
    // ----------------------------------------------------------------
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = DB::table('users')
            ->join('roles', 'users.role_id', '=', 'roles.id')
            ->select('users.*', 'roles.role_name')
            ->where('users.username', $request->username)
            ->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Username tidak ditemukan.',
            ], 401);
        }

        if (!Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Password salah.',
            ], 401);
        }

        if ($user->status_aktif !== 'Aktif') {
            return response()->json([
                'success' => false,
                'message' => 'Akun Anda tidak aktif. Hubungi Administrator.',
            ], 403);
        }

        // Staff (2), Pimpinan (3), dan Admin (1) bisa login mobile.
        // Admin dapat akses fitur krusial (scan inbound, checkout,
        // outbound, audit) lewat mobile selain via Web.
        if (!in_array($user->role_id, [1, 2, 3])) {
            return response()->json([
                'success' => false,
                'message' => 'Akses ditolak.',
            ], 403);
        }

        // Generate token
        $token = Str::random(60);
        DB::table('users')->where('id', $user->id)->update([
            'api_token'  => $token,
            'updated_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Login berhasil.',
            'data'    => [
                'token'        => $token,
                'id'           => $user->id,
                'nama_lengkap' => $user->nama_lengkap,
                'username'     => $user->username,
                'email'        => $user->email,
                'nomor_hp'     => $user->nomor_hp,
                'bagian'       => $user->bagian,
                'jabatan'      => $user->jabatan,
                'role_id'      => $user->role_id,
                'role_name'    => $user->role_name,
            ],
        ]);
    }

    // ----------------------------------------------------------------
    // POST /api/logout
    // ----------------------------------------------------------------
    public function logout(Request $request)
    {
        $user = $this->authUser($request);

        DB::table('users')->where('id', $user->id)->update([
            'api_token'  => null,
            'updated_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Logout berhasil.',
        ]);
    }

    // ----------------------------------------------------------------
    // GET /api/profile
    // ----------------------------------------------------------------
    public function profile(Request $request)
    {
        $user = $this->authUser($request);

        $data = DB::table('users')
            ->join('roles', 'users.role_id', '=', 'roles.id')
            ->select('users.*', 'roles.role_name')
            ->where('users.id', $user->id)
            ->first();

        return response()->json([
            'success' => true,
            'data'    => [
                'id'           => $data->id,
                'nama_lengkap' => $data->nama_lengkap,
                'username'     => $data->username,
                'email'        => $data->email,
                'nomor_hp'     => $data->nomor_hp,
                'bagian'       => $data->bagian,
                'jabatan'      => $data->jabatan,
                'role_id'      => $data->role_id,
                'role_name'    => $data->role_name,
                'status_aktif' => $data->status_aktif,
            ],
        ]);
    }

    // ----------------------------------------------------------------
    // GET /api/dashboard
    // ----------------------------------------------------------------
    public function dashboard(Request $request)
    {
        $user   = $this->authUser($request);
        $roleId = $user->role_id;

        if ($roleId === 1) {
            // Dashboard Admin — ringkasan dari 3 fitur mobile Admin
            $data = [
                'total_barang'        => DB::table('barang')->count(),
                'barang_stok_menipis' => DB::table('barang')
                    ->where('status_barang', 'Stok Menipis')->count(),
                'barang_habis'        => DB::table('barang')
                    ->where('status_barang', 'Habis')->count(),
                'siap_distribusi'     => DB::table('permintaan')
                    ->leftJoin('distribusi', 'permintaan.id', '=', 'distribusi.permintaan_id')
                    ->where('permintaan.status_permintaan', 'Approved')
                    ->whereNull('distribusi.id')
                    ->count(),
                'opname_berlangsung'  => DB::table('stock_opname')
                    ->where('admin_id', $user->id)
                    ->where('status_opname', 'Berlangsung')
                    ->exists(),
                'inbound_hari_ini'    => DB::table('riwayat_stok')
                    ->where('jenis_transaksi', 'Masuk')
                    ->whereDate('created_at', now()->toDateString())
                    ->count(),
                'notifikasi_belum_dibaca' => DB::table('notifikasi')
                    ->where('user_id', $user->id)
                    ->where('status_baca', 'Belum Dibaca')->count(),
            ];
        } elseif ($roleId === 2) {
            // Dashboard Staff
            $data = [
                'total_permintaan' => DB::table('permintaan')
                    ->where('user_id', $user->id)->count(),
                'pending'          => DB::table('permintaan')
                    ->where('user_id', $user->id)
                    ->where('status_permintaan', 'Pending')->count(),
                'approved'         => DB::table('permintaan')
                    ->where('user_id', $user->id)
                    ->where('status_permintaan', 'Approved')->count(),
                'distributed'      => DB::table('permintaan')
                    ->where('user_id', $user->id)
                    ->where('status_permintaan', 'Distributed')->count(),
                'notifikasi_belum_dibaca' => DB::table('notifikasi')
                    ->where('user_id', $user->id)
                    ->where('status_baca', 'Belum Dibaca')->count(),
                'permintaan_terbaru' => DB::table('permintaan')
                    ->where('user_id', $user->id)
                    ->orderBy('id', 'desc')
                    ->limit(5)
                    ->get(),
            ];
        } else {
            // Dashboard Pimpinan
            $data = [
                'total_permintaan'  => DB::table('permintaan')->count(),
                'menunggu_approval' => DB::table('permintaan')
                    ->where('status_permintaan', 'Pending')->count(),
                'sudah_diapprove'   => DB::table('approval')
                    ->where('pimpinan_id', $user->id)
                    ->where('keputusan', 'Approved')->count(),
                'sudah_direject'    => DB::table('approval')
                    ->where('pimpinan_id', $user->id)
                    ->where('keputusan', 'Rejected')->count(),
                'notifikasi_belum_dibaca' => DB::table('notifikasi')
                    ->where('user_id', $user->id)
                    ->where('status_baca', 'Belum Dibaca')->count(),
                'permintaan_terbaru' => DB::table('permintaan')
                    ->join('users', 'permintaan.user_id', '=', 'users.id')
                    ->select('permintaan.*', 'users.nama_lengkap', 'users.bagian')
                    ->where('permintaan.status_permintaan', 'Pending')
                    ->orderBy('permintaan.id', 'desc')
                    ->limit(5)
                    ->get(),
            ];
        }

        return response()->json([
            'success' => true,
            'data'    => $data,
        ]);
    }
}