<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ApiController;
use App\Http\Controllers\Api\PermintaanApiController;
use App\Http\Controllers\Api\ApprovalApiController;
use App\Http\Controllers\Api\NotifikasiApiController;
use App\Http\Controllers\Api\Admin\InboundApiController;
use App\Http\Controllers\Api\Admin\DistribusiScanApiController;
use App\Http\Controllers\Api\Admin\OpnameApiController;

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

    // ── Admin (mobile) ──────────────────────────────────────
    // Scan Inbound (Barang Masuk)
    Route::get('/admin/barang/{kode_barang}', [InboundApiController::class, 'cariBarang']);
    Route::post('/admin/inbound',             [InboundApiController::class, 'store']);
    Route::get('/admin/inbound/riwayat',      [InboundApiController::class, 'riwayat']);

    // Scan Checkout + Scan Outbound (Distribusi)
    Route::get('/admin/distribusi/siap',                 [DistribusiScanApiController::class, 'siapDistribusi']);
    Route::get('/admin/distribusi/riwayat',               [DistribusiScanApiController::class, 'riwayat']);
    Route::get('/admin/distribusi/{id}',                 [DistribusiScanApiController::class, 'detail']);
    Route::post('/admin/distribusi/{id}/checkout',        [DistribusiScanApiController::class, 'checkout']);
    Route::post('/admin/distribusi/{id}/outbound',        [DistribusiScanApiController::class, 'outbound']);

    // Scan Audit / Stock Opname
    Route::get('/admin/opname/aktif',              [OpnameApiController::class, 'aktif']);
    Route::post('/admin/opname/mulai',              [OpnameApiController::class, 'mulai']);
    Route::get('/admin/opname/riwayat',             [OpnameApiController::class, 'riwayat']);
    Route::get('/admin/opname/barang/{kode_barang}',[OpnameApiController::class, 'cariBarang']);
    Route::post('/admin/opname/{id}/scan',           [OpnameApiController::class, 'scan']);
    Route::post('/admin/opname/{id}/selesai',        [OpnameApiController::class, 'selesai']);
    Route::get('/admin/opname/{id}',                [OpnameApiController::class, 'detail']);

});