<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('permintaan', function (Blueprint $table) {
            // Token unik dibuat otomatis saat Pimpinan approve, ditampilkan
            // sebagai QR di HP User, lalu discan Admin saat Outbound untuk
            // konfirmasi barang fisik sudah diserahkan.
            $table->string('qr_token', 100)->nullable()->after('status_permintaan');
            $table->timestamp('qr_generated_at')->nullable()->after('qr_token');
        });
    }

    public function down(): void
    {
        Schema::table('permintaan', function (Blueprint $table) {
            $table->dropColumn(['qr_token', 'qr_generated_at']);
        });
    }
};
