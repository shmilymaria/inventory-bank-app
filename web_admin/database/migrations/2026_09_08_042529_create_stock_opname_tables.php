<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Versi PERBAIKAN dari migration yang sama (nama file tidak diubah).
 *
 * Perbaikan:
 *  1. stock_opname_detail.opname_id sekarang unsignedInteger — harus sama
 *     tipenya dengan stock_opname.id (increments = INT UNSIGNED), kalau
 *     beda, foreign key ditolak MySQL/MariaDB.
 *  2. Aman dijalankan ulang: tabel yang sudah ada dilewati (Schema::hasTable),
 *     jadi tidak error "Table already exists" kalau migration sebelumnya
 *     sempat gagal di tengah jalan.
 */
return new class extends Migration
{
    public function up(): void
    {
        // Sesi audit/opname — 1 baris per sesi yang dijalankan Admin
        if (!Schema::hasTable('stock_opname')) {
            Schema::create('stock_opname', function (Blueprint $table) {
                $table->increments('id');
                $table->integer('admin_id'); // signed, cocok dgn users.id (int(11))
                $table->timestamp('tanggal_mulai')->useCurrent();
                $table->timestamp('tanggal_selesai')->nullable();
                $table->enum('status_opname', ['Berlangsung', 'Selesai'])
                      ->default('Berlangsung');
                $table->text('catatan')->nullable();

                $table->foreign('admin_id')->references('id')->on('users');
            });
        }

        // Detail hasil scan per barang dalam 1 sesi opname
        if (!Schema::hasTable('stock_opname_detail')) {
            Schema::create('stock_opname_detail', function (Blueprint $table) {
                $table->increments('id');
                $table->unsignedInteger('opname_id'); // sama dgn stock_opname.id (unsigned)
                $table->integer('barang_id');         // signed, cocok dgn barang.id (int(11))
                $table->integer('stok_sistem'); // snapshot stok saat discan
                $table->integer('stok_fisik');  // hasil hitung fisik oleh Admin
                $table->integer('selisih');     // stok_fisik - stok_sistem
                $table->text('keterangan')->nullable();
                $table->timestamp('scanned_at')->useCurrent();

                $table->foreign('opname_id')->references('id')->on('stock_opname')
                      ->onDelete('cascade');
                $table->foreign('barang_id')->references('id')->on('barang');

                // 1 barang hanya 1 baris per sesi opname — scan ulang = update
                $table->unique(['opname_id', 'barang_id']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_opname_detail');
        Schema::dropIfExists('stock_opname');
    }
};