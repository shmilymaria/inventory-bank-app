<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\BarangController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\PermintaanController;
use App\Http\Controllers\DistribusiController;
use App\Http\Controllers\LaporanController;

// ----------------------------------------------------------------
// Public routes
// ----------------------------------------------------------------
Route::get('/', [AuthController::class, 'showLogin']);
Route::post('/login', [AuthController::class, 'login']);
Route::get('/logout', [AuthController::class, 'logout']);

// ----------------------------------------------------------------
// Protected routes
// ----------------------------------------------------------------
Route::middleware('auth.admin')->group(function () {

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'index']);

    // CRUD Barang
    Route::resource('barang', BarangController::class);

    // CRUD User
    Route::resource('user', UserController::class);
    Route::patch('/user/{id}/toggle-status', [UserController::class, 'toggleStatus'])
         ->name('user.toggleStatus');

    // Kelola Permintaan
    Route::get('/permintaan', [PermintaanController::class, 'index'])
         ->name('permintaan.index');
    Route::get('/permintaan/{id}', [PermintaanController::class, 'show'])
         ->name('permintaan.show');

    // Distribusi
    Route::get('/distribusi', [DistribusiController::class, 'index'])
         ->name('distribusi.index');
    Route::get('/distribusi/proses/{permintaan_id}', [DistribusiController::class, 'show'])
         ->name('distribusi.show');
    Route::post('/distribusi/proses/{permintaan_id}', [DistribusiController::class, 'store'])
         ->name('distribusi.store');
    Route::get('/distribusi/detail/{distribusi_id}', [DistribusiController::class, 'detail'])
         ->name('distribusi.detail');

     // Laporan
    Route::get('/laporan', [LaporanController::class, 'index'])
         ->name('laporan.index');
    Route::get('/laporan/barang', [LaporanController::class, 'barang'])
         ->name('laporan.barang');
    Route::get('/laporan/permintaan', [LaporanController::class, 'permintaan'])
         ->name('laporan.permintaan');
    Route::get('/laporan/distribusi', [LaporanController::class, 'distribusi'])
         ->name('laporan.distribusi');
    Route::get('/laporan/stok', [LaporanController::class, 'stok'])
         ->name('laporan.stok');
});