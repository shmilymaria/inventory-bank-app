<?php

namespace App\Support;

use Illuminate\Database\Query\Builder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

/**
 * Aturan alur permintaan di satu tempat.
 *
 * Alur berdasarkan prioritas:
 *   - Normal   (Rutin / stok aman)           → cukup diverifikasi Admin
 *   - Mendesak (Butuh hari ini)              → cukup diverifikasi Admin
 *   - Penting  (Kebutuhan khusus)            → Admin, lalu disposisi Pimpinan
 *
 * Status:
 *   Pending  → menunggu verifikasi Admin
 *   Verified → lolos Admin. Untuk Normal/Mendesak ini SUDAH FINAL (siap
 *              didistribusikan, QR terbit). Untuk Penting masih menunggu Pimpinan.
 *   Approved → disetujui Pimpinan (hanya prioritas Penting), siap didistribusikan.
 *   Rejected / Revision → dikembalikan ke User.
 *   Distributed / Cancelled → selesai / dibatalkan User (hanya saat Pending).
 */
class AlurPermintaan
{
    public const PRIORITAS             = ['Normal', 'Penting', 'Mendesak'];
    public const PRIORITAS_BUTUH_PIMPINAN = 'Penting';
    public const PRIORITAS_WAJIB_CATATAN  = ['Penting', 'Mendesak'];

    // ── Aturan prioritas ──────────────────────────────────────
    public static function butuhPimpinan(?string $prioritas): bool
    {
        return $prioritas === self::PRIORITAS_BUTUH_PIMPINAN;
    }

    public static function wajibCatatan(?string $prioritas): bool
    {
        return in_array($prioritas, self::PRIORITAS_WAJIB_CATATAN, true);
    }

    /** Teks singkat alur proses untuk ditampilkan ke pengguna. */
    public static function keteranganAlur(?string $prioritas): string
    {
        return self::butuhPimpinan($prioritas)
            ? 'Diverifikasi Admin, lalu disetujui Pimpinan'
            : 'Diproses Admin (tanpa persetujuan Pimpinan)';
    }

    // ── Definisi "siap didistribusikan" ───────────────────────
    /**
     * Siap didistribusikan =
     *   (status Approved)  ATAU  (status Verified DAN prioritas bukan Penting).
     */
    public static function siapDistribusi(object $permintaan): bool
    {
        return $permintaan->status_permintaan === 'Approved'
            || ($permintaan->status_permintaan === 'Verified'
                && !self::butuhPimpinan($permintaan->prioritas));
    }

    /** Tambahkan kondisi "siap didistribusikan" ke query tabel permintaan. */
    public static function scopeSiapDistribusi(Builder $query, string $tabel = 'permintaan'): Builder
    {
        return $query->where(function ($q) use ($tabel) {
            $q->where("$tabel.status_permintaan", 'Approved')
              ->orWhere(function ($q2) use ($tabel) {
                  $q2->where("$tabel.status_permintaan", 'Verified')
                     ->where("$tabel.prioritas", '<>', self::PRIORITAS_BUTUH_PIMPINAN);
              });
        });
    }

    /** Terbitkan QR serah terima kalau permintaan sudah siap & belum punya QR. */
    public static function terbitkanQrJikaSiap(int $permintaanId): void
    {
        $p = DB::table('permintaan')->where('id', $permintaanId)->first();
        if ($p && empty($p->qr_token) && self::siapDistribusi($p)) {
            DB::table('permintaan')->where('id', $permintaanId)->update([
                'qr_token'        => Str::random(40),
                'qr_generated_at' => now(),
            ]);
        }
    }

    /** Pada tahap mana Revision terakhir diminta? ('Admin' / 'Pimpinan' / null) */
    public static function tahapRevisiTerakhir(int $permintaanId): ?string
    {
        return DB::table('approval')
            ->where('permintaan_id', $permintaanId)
            ->where('keputusan', 'Revision')
            ->orderByDesc('tanggal_approval')
            ->orderByDesc('id')
            ->value('tahap');
    }

    // ── Kelompok kategori untuk katalog (ATK / Barang Cetakan / Barang Lainnya) ──
    public static function kelompokKategoriSql(string $kolom = 'kategori_barang.nama_kategori'): string
    {
        return "CASE {$kolom} " .
               "WHEN 'Alat Tulis Kantor' THEN 'ATK' " .
               "WHEN 'Barang Cetakan' THEN 'Barang Cetakan' " .
               "ELSE 'Barang Lainnya' END";
    }

    // ── Notifikasi (selalu membawa permintaan_id untuk deep link) ──
    public static function notifikasi(int $userId, string $judul, string $pesan, ?int $permintaanId = null): void
    {
        DB::table('notifikasi')->insert([
            'user_id'       => $userId,
            'permintaan_id' => $permintaanId,
            'judul'         => $judul,
            'pesan'         => $pesan,
            'status_baca'   => 'Belum Dibaca',
            'created_at'    => now(),
        ]);
    }

    /** Kirim notifikasi ke semua user aktif dengan role tertentu (1=Admin, 3=Pimpinan). */
    public static function notifikasiKeRole(
        int $roleId,
        string $judul,
        string $pesan,
        ?int $permintaanId = null,
        ?int $kecualiUserId = null
    ): void {
        $ids = DB::table('users')
            ->where('role_id', $roleId)
            ->where('status_aktif', 'Aktif')
            ->when($kecualiUserId, fn($q) => $q->where('id', '<>', $kecualiUserId))
            ->pluck('id');

        foreach ($ids as $id) {
            self::notifikasi((int) $id, $judul, $pesan, $permintaanId);
        }
    }

    // ── Catatan perubahan (Edit / Revisi / Batal) ─────────────
    public static function catatLog(int $permintaanId, int $userId, string $jenis, ?string $ringkasan): void
    {
        DB::table('permintaan_log')->insert([
            'permintaan_id' => $permintaanId,
            'user_id'       => $userId,
            'jenis'         => $jenis,
            'ringkasan'     => $ringkasan,
            'created_at'    => now(),
        ]);
    }

    /** Riwayat perubahan satu permintaan, terbaru di atas. */
    public static function riwayatPerubahan(int $permintaanId)
    {
        return DB::table('permintaan_log')
            ->join('users', 'permintaan_log.user_id', '=', 'users.id')
            ->select('permintaan_log.*', 'users.nama_lengkap as nama_pelaku')
            ->where('permintaan_log.permintaan_id', $permintaanId)
            ->orderByDesc('permintaan_log.id')
            ->get();
    }
}
