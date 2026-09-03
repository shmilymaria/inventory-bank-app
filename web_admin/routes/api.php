<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ApiController;
use App\Http\Controllers\Api\PermintaanApiController;
use App\Http\Controllers\Api\ApprovalApiController;
use App\Http\Controllers\Api\NotifikasiApiController;

// ----------------------------------------------------------------
// Public API — tidak perlu token
// ----------------------------------------------------------------
Route::post('/login', [ApiController::class, 'login']);

// ----------------------------------------------------------------
// Protected API — wajib token (Bearer)
// ----------------------------------------------------------------
Route::middleware('auth.api')->group(function () {

    // Auth
    Route::post('/logout',  [ApiController::class, 'logout']);
    Route::get('/profile',  [ApiController::class, 'profile']);
    Route::get('/dashboard',[ApiController::class, 'dashboard']);

    // Permintaan (Staff)
    Route::get('/barang',              [PermintaanApiController::class, 'daftarBarang']);
    Route::get('/permintaan',          [PermintaanApiController::class, 'index']);
    Route::get('/permintaan/{id}',     [PermintaanApiController::class, 'show']);
    Route::post('/permintaan',         [PermintaanApiController::class, 'store']);

    // Approval (Pimpinan)
    Route::get('/approval',            [ApprovalApiController::class, 'index']);
    Route::get('/approval/{id}',       [ApprovalApiController::class, 'show']);
    Route::post('/approval/{id}',      [ApprovalApiController::class, 'store']);
    Route::get('/riwayat-approval',    [ApprovalApiController::class, 'riwayat']);

    // Notifikasi (semua role)
    Route::get('/notifikasi',                      [NotifikasiApiController::class, 'index']);
    Route::patch('/notifikasi/{id}/baca',          [NotifikasiApiController::class, 'tandaiBaca']);
    Route::patch('/notifikasi/baca-semua',         [NotifikasiApiController::class, 'bacaSemua']);

});