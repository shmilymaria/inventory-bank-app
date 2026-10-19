<?php

namespace App\Services;

use App\Support\AlurPermintaan;
use Illuminate\Support\Facades\DB;

/**
 * Keputusan Admin (bagian umum) atas permintaan yang baru diajukan User.
 *
 *   Approved → status 'Verified'
 *                • prioritas Normal / Mendesak : FINAL — siap didistribusikan,
 *                  QR serah terima terbit, TIDAK diteruskan ke Pimpinan
 *                • prioritas Penting           : diteruskan ke Pimpinan
 *   Rejected → status 'Rejected', kembali ke User
 *   Revision → status 'Revision', kembali ke User (User merevisi di
 *              permintaan yang sama, nomor tetap)
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
        // yang jadi pegangan User saat merevisi permintaannya.
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

        $statusBaru   = $keputusan === 'Approved' ? 'Verified' : $keputusan;
        $nomor        = $permintaan->nomor_permintaan;
        $butuhPimpinan = AlurPermintaan::butuhPimpinan($permintaan->prioritas);

        DB::transaction(function () use (
            $permintaanId, $admin, $keputusan, $catatan, $statusBaru,
            $permintaan, $nomor, $butuhPimpinan
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
            if ($keputusan === 'Approved') {
                $pesanUser = $butuhPimpinan
                    ? "Permintaan $nomor telah DIVERIFIKASI oleh Admin " .
                      "({$admin->nama_lengkap}) dan diteruskan ke Pimpinan untuk " .
                      "disposisi (prioritas {$permintaan->prioritas})."
                    : "Permintaan $nomor telah DISETUJUI oleh Admin " .
                      "({$admin->nama_lengkap}). Prioritas {$permintaan->prioritas} " .
                      "tidak memerlukan persetujuan Pimpinan, barang siap diambil. " .
                      "Tunjukkan QR Serah Terima ke Admin.";
            } elseif ($keputusan === 'Rejected') {
                $pesanUser = "Permintaan $nomor DITOLAK oleh Admin " .
                             "({$admin->nama_lengkap}). Catatan: $catatan. " .
                             "Silakan ajukan permintaan baru bila diperlukan.";
            } else {
                $pesanUser = "Permintaan $nomor perlu DIREVISI. Catatan dari Admin " .
                             "({$admin->nama_lengkap}): $catatan. " .
                             "Buka permintaan tersebut lalu tekan Revisi — nomor " .
                             "permintaan tetap sama, tidak perlu membuat permintaan baru.";
            }

            AlurPermintaan::notifikasi(
                (int) $permintaan->user_id,
                'Update Status Permintaan',
                $pesanUser,
                $permintaanId
            );

            if ($keputusan === 'Approved') {
                if ($butuhPimpinan) {
                    // Prioritas Penting → kabari semua Pimpinan aktif
                    $pemohon = DB::table('users')->where('id', $permintaan->user_id)->first();

                    AlurPermintaan::notifikasiKeRole(
                        3,
                        'Permintaan Menunggu Disposisi',
                        "Permintaan $nomor dari " . ($pemohon->nama_lengkap ?? '-') . ' (' .
                        ($pemohon->bagian ?? '-') . ') prioritas Penting ' .
                        'telah diverifikasi Admin dan menunggu persetujuan Anda.',
                        $permintaanId
                    );
                } else {
                    // Final di Admin → terbitkan QR, kabari Admin lain
                    AlurPermintaan::terbitkanQrJikaSiap($permintaanId);

                    AlurPermintaan::notifikasiKeRole(
                        1,
                        'Permintaan Siap Didistribusikan',
                        "Permintaan $nomor sudah diverifikasi dan siap diproses " .
                        "(Scan Checkout & Outbound).",
                        $permintaanId,
                        (int) $admin->id
                    );
                }
            }
        });

        $pesanSukses = [
            'Approved' => $butuhPimpinan
                ? "Permintaan $nomor diverifikasi dan diteruskan ke Pimpinan."
                : "Permintaan $nomor diverifikasi dan siap didistribusikan " .
                  "(tidak perlu persetujuan Pimpinan).",
            'Rejected' => "Permintaan $nomor ditolak dan dikembalikan ke User.",
            'Revision' => "Permintaan $nomor dikembalikan ke User untuk direvisi.",
        ];

        return ['ok' => true, 'message' => $pesanSukses[$keputusan]];
    }
}
