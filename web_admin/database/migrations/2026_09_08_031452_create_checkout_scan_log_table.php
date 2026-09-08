<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('checkout_scan_log', function (Blueprint $table) {
            // PK sendiri, tidak direferensikan tabel lain, jadi aman pakai
            // increments() bawaan Laravel meski beda signedness dgn tabel lama.
            $table->increments('id');

            // Kolom FK dibuat 'integer' polos (signed) supaya cocok dengan
            // tipe int(11) signed pada tabel permintaan/detail_permintaan/
            // barang/users yang sudah ada (dibuat manual, bukan via migration).
            $table->integer('permintaan_id');
            $table->integer('detail_permintaan_id');
            $table->integer('barang_id');
            $table->integer('admin_id');

            $table->string('kode_scan', 100);
            $table->enum('status_scan', ['Cocok', 'Tidak Cocok'])->default('Cocok');
            $table->timestamp('scanned_at')->useCurrent();

            $table->foreign('permintaan_id')->references('id')->on('permintaan');
            $table->foreign('detail_permintaan_id')->references('id')->on('detail_permintaan');
            $table->foreign('barang_id')->references('id')->on('barang');
            $table->foreign('admin_id')->references('id')->on('users');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('checkout_scan_log');
    }
};
