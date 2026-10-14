<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * Keputusan Admin (bagian umum) atas permintaan yang baru diajukan User.
 *
 *   Approved → status 'Verified', diteruskan ke Pimpinan
 *   Rejected → status 'Rejected', kembali ke User
 *   Revision → status 'Revision', kembali ke User
 *
 * Dipakai bersama oleh API mobile (Api\Admin\VerifikasiApiController)
 * dan web admin (PermintaanController@verifikasi) supaya logikanya satu.
 */
class VerifikasiService
{
    public const KEPUTUSAN = ['Approved', 'Rejected', 'Revision'];

    /**
     * @param  object      $admin      baris user (role Admin) yang memutuskan
     * @return array{ok: bool, message: string}
     */
    public static function proses(
        int $permintaanId,
        object $admin,
        string $keputusan,
        ?string $catatan
    ): array {
        if (!in_array($keputusan, self::KEPUTUSAN, true)) {
            return ['ok' => false, 'message' => 'Keputusan tidak valid.'];
        }

        $catatan = $catatan !== null ? trim($catatan) : null;

        // Rejected / Revision wajib disertai catatan, karena catatan inilah
        // yang jadi pegangan User saat mengajukan permintaan ulang.
        if ($keputusan !== 'Approved' && ($catatan === null || $catatan === '')) {
            return [
                'ok'      => false,
                'message' => 'Catatan wajib diisi untuk keputusan Rejected / Revision.',
            ];
        }

        $permintaan = DB::table('permintaan')
            ->where('id', $permintaanId)
            ->where('status_permintaan', 'Pending')
            ->first();

        if (!$permintaan) {
            return [
                'ok'      => false,
                'message' => 'Permintaan tidak ditemukan atau sudah diverifikasi.',
            ];
        }

        $statusBaru = $keputusan === 'Approved' ? 'Verified' : $keputusan;
        $nomor      = $permintaan->nomor_permintaan;

        DB::transaction(function () use (
            $permintaanId, $admin, $keputusan, $catatan, $statusBaru, $permintaan, $nomor
        ) {
            DB::table('approval')->insert([
                'permintaan_id'    => $permintaanId,
                'pimpinan_id'      => $admin->id,   // ID pengambil keputusan (Admin)
                'tahap'            => 'Admin',
                'keputusan'        => $keputusan,
                'catatan_approval' => $catatan,
                'tanggal_approval' => now(),
            ]);

            DB::table('permintaan')->where('id', $permintaanId)->update([
                'status_permintaan' => $statusBaru,
            ]);

            // ── Notifikasi ke User pemohon ───────────────────────
            $pesanUser = [
                'Approved' => "Permintaan $nomor telah DIVERIFIKASI oleh Admin " .
                              "({$admin->nama_lengkap}) dan diteruskan ke Pimpinan " .
                              "untuk disposisi.",
                'Rejected' => "Permintaan $nomor DITOLAK oleh Admin " .
                              "({$admin->nama_lengkap}). Catatan: $catatan. " .
                              "Silakan ajukan permintaan ulang bila diperlukan.",
                'Revision' => "Permintaan $nomor perlu DIREVISI. Catatan dari Admin " .
                              "({$admin->nama_lengkap}): $catatan. " .
                              "Silakan ajukan permintaan ulang sesuai catatan tersebut.",
            ];

            DB::table('notifikasi')->insert([
                'user_id'     => $permintaan->user_id,
                'judul'       => 'Update Status Permintaan',
                'pesan'       => $pesanUser[$keputusan],
                'status_baca' => 'Belum Dibaca',
                'created_at'  => now(),
            ]);

            // ── Kalau disetujui Admin, kabari semua Pimpinan aktif ──
            if ($keputusan === 'Approved') {
                $pemohon = DB::table('users')->where('id', $permintaan->user_id)->first();

                $pimpinan = DB::table('users')
                    ->where('role_id', 3)
                    ->where('status_aktif', 'Aktif')
                    ->get();

                foreach ($pimpinan as $p) {
                    DB::table('notifikasi')->insert([
                        'user_id'     => $p->id,
                        'judul'       => 'Permintaan Menunggu Disposisi',
                        'pesan'       => "Permintaan $nomor dari " .
                                         ($pemohon->nama_lengkap ?? '-') . ' (' .
                                         ($pemohon->bagian ?? '-') . ') ' .
                                         'telah diverifikasi Admin dan menunggu persetujuan Anda.',
                        'status_baca' => 'Belum Dibaca',
                        'created_at'  => now(),
                    ]);
                }
            }
        });

        $pesanSukses = [
            'Approved' => "Permintaan $nomor diverifikasi dan diteruskan ke Pimpinan.",
            'Rejected' => "Permintaan $nomor ditolak dan dikembalikan ke User.",
            'Revision' => "Permintaan $nomor dikembalikan ke User untuk direvisi.",
        ];

        return ['ok' => true, 'message' => $pesanSukses[$keputusan]];
    }
}
