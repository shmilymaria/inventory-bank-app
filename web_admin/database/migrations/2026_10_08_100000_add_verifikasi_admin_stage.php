<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Alur approval 2 tahap:
 *   User ajukan (Pending) → Admin verifikasi → (Verified) → Pimpinan disposisi
 *   → (Approved) → Admin distribusi (Distributed).
 *   Rejected / Revision dari tahap manapun dikembalikan ke User.
 *
 * - Status baru 'Verified' = sudah disetujui Admin, menunggu Pimpinan.
 * - approval.tahap membedakan keputusan Admin vs Pimpinan.
 *   (Kolom approval.pimpinan_id tetap dipakai untuk menyimpan ID user
 *   pengambil keputusan di tahap manapun — namanya dipertahankan supaya
 *   kode lama tidak rusak.)
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::statement(
            "ALTER TABLE `permintaan` MODIFY `status_permintaan` " .
            "ENUM('Pending','Verified','Approved','Rejected','Revision','Distributed') " .
            "DEFAULT 'Pending'"
        );

        // Dilewati kalau kolom sudah ada (aman dijalankan ulang)
        if (!Schema::hasColumn('approval', 'tahap')) {
            Schema::table('approval', function (Blueprint $table) {
                // Data lama semuanya keputusan Pimpinan, jadi default 'Pimpinan'
                $table->enum('tahap', ['Admin', 'Pimpinan'])
                      ->default('Pimpinan')
                      ->after('pimpinan_id');
            });
        }
    }

    public function down(): void
    {
        // Kembalikan permintaan yang sedang 'Verified' ke 'Pending'
        // sebelum enum dipersempit, supaya tidak error.
        DB::table('permintaan')->where('status_permintaan', 'Verified')
            ->update(['status_permintaan' => 'Pending']);

        if (Schema::hasColumn('approval', 'tahap')) {
            Schema::table('approval', function (Blueprint $table) {
                $table->dropColumn('tahap');
            });
        }

        DB::statement(
            "ALTER TABLE `permintaan` MODIFY `status_permintaan` " .
            "ENUM('Pending','Approved','Rejected','Revision','Distributed') " .
            "DEFAULT 'Pending'"
        );
    }
};