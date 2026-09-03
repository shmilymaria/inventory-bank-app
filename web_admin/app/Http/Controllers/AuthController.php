<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function showLogin()
    {
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $user = DB::table('users')
            ->where('username', $request->username)
            ->first();

        if (!$user) {
            return back()->with('error', 'Username tidak ditemukan');
        }

        if (!Hash::check($request->password, $user->password)) {
            return back()->with('error', 'Password salah');
        }

        if ($user->role_id != 1) {
            return back()->with('error', 'Akses hanya untuk Admin');
        }

        session([
            'user_id' => $user->id,
            'nama' => $user->nama_lengkap,
            'role_id' => $user->role_id
        ]);

        return redirect('/dashboard');
    }

    public function logout()
    {
        session()->flush();

        return redirect('/');
    }
}