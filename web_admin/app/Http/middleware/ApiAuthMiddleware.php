<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\Response;

class ApiAuthMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();

        if (!$token) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak ditemukan. Silakan login terlebih dahulu.',
            ], 401);
        }

        $user = DB::table('users')
            ->where('api_token', $token)
            ->where('status_aktif', 'Aktif')
            ->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Token tidak valid atau akun tidak aktif.',
            ], 401);
        }

        // ── PERBAIKAN: gunakan request->attributes->set()
        // bukan merge() karena merge() tidak support stdClass object
        $request->attributes->set('auth_user', $user);

        return $next($request);
    }
}