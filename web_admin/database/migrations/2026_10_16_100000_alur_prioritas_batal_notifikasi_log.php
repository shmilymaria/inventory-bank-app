<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

/**
 * Perubahan alur permintaan (versi User baru):
 *
 *  1. Status baru 'Cancelled' (User membatalkan permintaan yang masih Pending).
 *  2. notifikasi.permintaan_id → deep link: klik notifikasi langsung ke
 *     detail permintaan. Notifikasi lama dipulihkan tautannya lewat nomor
 *     permintaan yang tertulis di teks pesannya.
 *  3. Tabel permintaan_log → catatan waktu Edit / Revisi / Batal.
 *  4. Kategori 'Barang Cetakan' (formulir, buku cek, slip, dll).
 *  5. Alur berdasarkan prioritas: hanya prioritas 'Penting' yang butuh
 *     persetujuan Pimpinan. Permintaan Normal/Mendesak yang sudah terlanjur
 *     'Verified' (menunggu Pimpinan di alur lama) kini langsung siap
 *     didistribusikan, jadi QR serah terimanya diterbitkan di sini.
 *
 * Aman dijalankan ulang (setiap langkah dicek dulu).
 */
return new class extends Migration
{
    public function up(): void
    {
        // ── 1) Status 'Cancelled' ───────────────────────────────
        DB::statement(
            "ALTER TABLE `permintaan` MODIFY `status_permintaan` " .
            "ENUM('Pending','Verified','Approved','Rejected','Revision','Distributed','Cancelled') " .
            "DEFAULT 'Pending'"
        );

        // ── 2) notifikasi.permintaan_id ─────────────────────────
        if (!Schema::hasColumn('notifikasi', 'permintaan_id')) {
            Schema::table('notifikasi', function (Blueprint $table) {
                // signed int(11), sama dengan permintaan.id (dibuat manual, bukan unsigned)
                $table->integer('permintaan_id')->nullable()->after('user_id');
                $table->foreign('permintaan_id', 'fk_notifikasi_permintaan')
                      ->references('id')->on('permintaan')
                      ->nullOnDelete();
            });
        }

        // Pulihkan tautan notifikasi lama dari nomor permintaan di teks pesan
        DB::statement(
            "UPDATE `notifikasi` n " .
            "JOIN `permintaan` p ON n.`pesan` LIKE CONCAT('%', p.`nomor_permintaan`, '%') " .
            "SET n.`permintaan_id` = p.`id` " .
            "WHERE n.`permintaan_id` IS NULL"
        );

        // ── 3) permintaan_log ───────────────────────────────────
        if (!Schema::hasTable('permintaan_log')) {
            Schema::create('permintaan_log', function (Blueprint $table) {
                $table->increments('id');
                // FK ke tabel lama (int(11) signed) → kolom FK juga signed
                $table->integer('permintaan_id');
                $table->integer('user_id');
                $table->enum('jenis', ['Edit', 'Revisi', 'Batal']);
                $table->text('ringkasan')->nullable();
                $table->timestamp('created_at')->useCurrent();

                $table->foreign('permintaan_id')->references('id')->on('permintaan')
                      ->onDelete('cascade');
                $table->foreign('user_id')->references('id')->on('users');
            });
        }

        // ── 4) Kategori 'Barang Cetakan' ────────────────────────
        if (!DB::table('kategori_barang')->where('nama_kategori', 'Barang Cetakan')->exists()) {
            DB::table('kategori_barang')->insert([
                'nama_kategori' => 'Barang Cetakan',
                'created_at'    => now(),
            ]);
        }

        // ── 5) QR untuk permintaan non-Penting yang sudah 'Verified' ──
        $idSiap = DB::table('permintaan')
            ->where('status_permintaan', 'Verified')
            ->where('prioritas', '<>', 'Penting')
            ->whereNull('qr_token')
            ->pluck('id');

        foreach ($idSiap as $id) {
            DB::table('permintaan')->where('id', $id)->update([
                'qr_token'        => Str::random(40),
                'qr_generated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('permintaan_log');

        if (Schema::hasColumn('notifikasi', 'permintaan_id')) {
            Schema::table('notifikasi', function (Blueprint $table) {
                $table->dropForeign('fk_notifikasi_permintaan');
                $table->dropColumn('permintaan_id');
            });
        }

        DB::table('permintaan')->where('status_permintaan', 'Cancelled')
            ->update(['status_permintaan' => 'Rejected']);

        DB::statement(
            "ALTER TABLE `permintaan` MODIFY `status_permintaan` " .
            "ENUM('Pending','Verified','Approved','Rejected','Revision','Distributed') " .
            "DEFAULT 'Pending'"
        );
        // Kategori 'Barang Cetakan' sengaja tidak dihapus (bisa sudah dipakai barang).
    }
};
