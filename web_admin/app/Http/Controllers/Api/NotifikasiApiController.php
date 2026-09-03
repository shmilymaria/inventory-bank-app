<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class NotifikasiApiController extends Controller
{
    // ── Helper ambil auth_user ────────────────────────────
    private function authUser(Request $request)
    {
        return $request->attributes->get('auth_user');
    }

    // ----------------------------------------------------------------
    // GET /api/notifikasi
    // ----------------------------------------------------------------
    public function index(Request $request)
    {
        $user = $this->authUser($request);

        $notifikasi = DB::table('notifikasi')
            ->where('user_id', $user->id)
            ->orderBy('id', 'desc')
            ->get();

        $belumDibaca = $notifikasi
            ->where('status_baca', 'Belum Dibaca')
            ->count();

        return response()->json([
            'success'      => true,
            'belum_dibaca' => $belumDibaca,
            'data'         => $notifikasi,
        ]);
    }

    // ----------------------------------------------------------------
    // PATCH /api/notifikasi/{id}/baca
    // ----------------------------------------------------------------
    public function tandaiBaca(Request $request, int $id)
    {
        $user    = $this->authUser($request);
        $updated = DB::table('notifikasi')
            ->where('id', $id)
            ->where('user_id', $user->id)
            ->update(['status_baca' => 'Sudah Dibaca']);

        if (!$updated) {
            return response()->json([
                'success' => false,
                'message' => 'Notifikasi tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Notifikasi ditandai sudah dibaca.',
        ]);
    }

    // ----------------------------------------------------------------
    // PATCH /api/notifikasi/baca-semua
    // ----------------------------------------------------------------
    public function bacaSemua(Request $request)
    {
        $user = $this->authUser($request);

        DB::table('notifikasi')
            ->where('user_id', $user->id)
            ->where('status_baca', 'Belum Dibaca')
            ->update(['status_baca' => 'Sudah Dibaca']);

        return response()->json([
            'success' => true,
            'message' => 'Semua notifikasi telah ditandai sudah dibaca.',
        ]);
    }
}