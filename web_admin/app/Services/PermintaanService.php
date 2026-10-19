<?php

namespace App\Services;

use App\Support\AlurPermintaan;
use Illuminate\Support\Facades\DB;

/**
 * Operasi User atas permintaan miliknya.
 *
 *  - buat()      : ajukan permintaan baru (status Pending)
 *  - ubah(edit)  : ubah permintaan yang masih Pending
 *  - ubah(revisi): kirim ulang revisi pada permintaan yang SAMA (nomor tetap)
 *  - batalkan()  : batalkan permintaan yang masih Pending
 *
 * Aturan Edit & Revisi (divalidasi di server, bukan hanya di layar):
 *   - boleh: ubah jumlah, ubah prioritas & catatan, hapus item
 *   - TIDAK boleh: menambah barang baru
 *   - minimal 1 item tersisa, jumlah minimal 1 dan tidak melebihi stok
 *   - catatan wajib untuk prioritas Penting / Mendesak
 */
class PermintaanService
{
    private static function gagal(string $pesan, int $kode = 422): array
    {
        return ['ok' => false, 'message' => $pesan, 'kode' => $kode];
    }

    private static function cekCatatan(string $prioritas, ?string $catatan): ?string
    {
        if (AlurPermintaan::wajibCatatan($prioritas) && trim((string) $catatan) === '') {
            return "Catatan wajib diisi untuk prioritas $prioritas.";
        }
        return null;
    }

    // ================================================================
    // AJUKAN BARU
    // ================================================================
    public static function buat(object $user, string $prioritas, ?string $catatan, array $items): array
    {
        if (!in_array($prioritas, AlurPermintaan::PRIORITAS, true)) {
            return self::gagal('Prioritas tidak valid.');
        }
        if ($err = self::cekCatatan($prioritas, $catatan)) {
            return self::gagal($err);
        }

        // Gabungkan barang yang dikirim ganda (jumlah dijumlahkan)
        $gabung = [];
        foreach ($items as $it) {
            $bid = (int) $it['barang_id'];
            if (!isset($gabung[$bid])) {
                $gabung[$bid] = [
                    'barang_id'  => $bid,
                    'jumlah'     => 0,
                    'keterangan' => $it['keterangan'] ?? null,
                ];
            }
            $gabung[$bid]['jumlah'] += (int) $it['jumlah'];
        }

        foreach ($gabung as $b) {
            $barang = DB::table('barang')->where('id', $b['barang_id'])->first();
            if (!$barang) {
                return self::gagal('Barang tidak ditemukan.');
            }
            if ($b['jumlah'] > (int) $barang->stok) {
                return self::gagal(
                    "Stok \"{$barang->nama_barang}\" hanya tersedia {$barang->stok} {$barang->satuan}."
                );
            }
        }

        $catatan = trim((string) $catatan) === '' ? null : trim($catatan);

        $tahun = date('Y');
        $bulan = date('m');
        $count = DB::table('permintaan')
            ->whereYear('created_at', $tahun)
            ->whereMonth('created_at', $bulan)
            ->count() + 1;
        $nomor = 'REQ-' . $tahun . $bulan . '-' . str_pad($count, 4, '0', STR_PAD_LEFT);

        $permintaanId = DB::transaction(function () use ($user, $prioritas, $catatan, $gabung, $nomor) {
            $id = DB::table('permintaan')->insertGetId([
                'nomor_permintaan'   => $nomor,
                'user_id'            => $user->id,
                'tanggal_permintaan' => now(),
                'prioritas'          => $prioritas,
                'catatan'            => $catatan,
                'status_permintaan'  => 'Pending',
                'created_at'         => now(),
            ]);

            foreach ($gabung as $b) {
                DB::table('detail_permintaan')->insert([
                    'permintaan_id' => $id,
                    'barang_id'     => $b['barang_id'],
                    'jumlah'        => $b['jumlah'],
                    'keterangan'    => $b['keterangan'],
                ]);
            }

            // Semua permintaan baru lebih dulu diverifikasi Admin
            AlurPermintaan::notifikasiKeRole(
                1,
                'Permintaan Baru Perlu Verifikasi',
                "Permintaan $nomor dari {$user->nama_lengkap} (" . ($user->bagian ?? '-') .
                ") prioritas $prioritas menunggu verifikasi Anda.",
                $id
            );

            return $id;
        });

        return [
            'ok'      => true,
            'kode'    => 201,
            'message' => "Permintaan berhasil diajukan dengan nomor $nomor.",
            'data'    => ['id' => $permintaanId, 'nomor_permintaan' => $nomor],
        ];
    }

    // ================================================================
    // EDIT (status Pending)  &  REVISI (status Revision) — permintaan sama
    // ================================================================
    /**
     * @param string $mode   'edit' | 'revisi'
     * @param array  $items  [['detail_id' => int, 'jumlah' => int], ...]
     */
    public static function ubah(
        int $permintaanId,
        object $user,
        string $mode,
        string $prioritas,
        ?string $catatan,
        array $items
    ): array {
        if (!in_array($prioritas, AlurPermintaan::PRIORITAS, true)) {
            return self::gagal('Prioritas tidak valid.');
        }
        if ($err = self::cekCatatan($prioritas, $catatan)) {
            return self::gagal($err);
        }

        $statusSyarat = $mode === 'revisi' ? 'Revision' : 'Pending';

        return DB::transaction(function () use (
            $permintaanId, $user, $mode, $prioritas, $catatan, $items, $statusSyarat
        ) {
            // Kunci baris supaya tidak bentrok dengan keputusan Admin/Pimpinan
            $p = DB::table('permintaan')
                ->where('id', $permintaanId)
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->first();

            if (!$p) {
                return self::gagal('Permintaan tidak ditemukan.', 404);
            }
            if ($p->status_permintaan !== $statusSyarat) {
                return self::gagal(
                    $mode === 'revisi'
                        ? 'Permintaan ini tidak sedang menunggu revisi.'
                        : 'Permintaan tidak bisa diedit karena sudah diproses. ' .
                          'Hanya permintaan berstatus Pending yang dapat diedit.',
                    409
                );
            }

            $lama = DB::table('detail_permintaan')
                ->join('barang', 'detail_permintaan.barang_id', '=', 'barang.id')
                ->select(
                    'detail_permintaan.id',
                    'detail_permintaan.barang_id',
                    'detail_permintaan.jumlah',
                    'barang.nama_barang',
                    'barang.satuan',
                    'barang.stok'
                )
                ->where('detail_permintaan.permintaan_id', $permintaanId)
                ->get()
                ->keyBy('id');

            // Normalisasi kiriman → [detail_id => jumlah]
            $kiriman = [];
            foreach ($items as $it) {
                $did = (int) ($it['detail_id'] ?? 0);
                $jml = $it['jumlah'] ?? null;

                if (!$lama->has($did)) {
                    return self::gagal(
                        'Item tidak valid. Barang baru tidak dapat ditambahkan ke ' .
                        'permintaan yang sudah diajukan.'
                    );
                }
                if (isset($kiriman[$did])) {
                    return self::gagal('Terdapat item yang dikirim ganda.');
                }
                if (!is_numeric($jml) || (int) $jml < 1) {
                    return self::gagal(
                        'Jumlah tiap barang minimal 1. Hapus item bila tidak jadi diminta.'
                    );
                }
                $kiriman[$did] = (int) $jml;
            }

            if (count($kiriman) < 1) {
                return self::gagal(
                    'Minimal harus ada 1 barang. Gunakan Batalkan Permintaan bila ' .
                    'tidak jadi meminta.'
                );
            }

            // Jumlah tidak boleh melebihi stok yang tersedia saat ini
            foreach ($kiriman as $did => $jml) {
                $baris = $lama[$did];
                if ($jml > (int) $baris->stok) {
                    return self::gagal(
                        "Stok \"{$baris->nama_barang}\" hanya tersedia " .
                        "{$baris->stok} {$baris->satuan}."
                    );
                }
            }

            // ── Hitung perubahan (untuk ringkasan log) ──────────
            $perubahan = [];
            foreach ($lama as $did => $row) {
                if (!isset($kiriman[$did])) {
                    $perubahan[] = "Hapus {$row->nama_barang}";
                } elseif ($kiriman[$did] !== (int) $row->jumlah) {
                    $perubahan[] = "{$row->nama_barang}: {$row->jumlah} → {$kiriman[$did]} {$row->satuan}";
                }
            }
            if ($p->prioritas !== $prioritas) {
                $perubahan[] = "Prioritas: {$p->prioritas} → $prioritas";
            }
            $catatanBaru = trim((string) $catatan) === '' ? null : trim($catatan);
            $catatanLama = trim((string) $p->catatan) === '' ? null : trim($p->catatan);
            if ($catatanLama !== $catatanBaru) {
                $perubahan[] = 'Catatan diubah';
            }

            if (!$perubahan) {
                return self::gagal(
                    'Belum ada perubahan. Ubah jumlah, prioritas, catatan, atau ' .
                    'hapus item terlebih dahulu.'
                );
            }

            // ── Terapkan ────────────────────────────────────────
            foreach ($lama as $did => $row) {
                if (!isset($kiriman[$did])) {
                    DB::table('detail_permintaan')->where('id', $did)->delete();
                } elseif ($kiriman[$did] !== (int) $row->jumlah) {
                    DB::table('detail_permintaan')->where('id', $did)
                        ->update(['jumlah' => $kiriman[$did]]);
                }
            }

            // Edit: tetap Pending. Revisi: kembali ke tahap yang meminta revisi.
            if ($mode === 'edit') {
                $statusBaru = 'Pending';
            } else {
                $statusBaru = AlurPermintaan::tahapRevisiTerakhir($permintaanId) === 'Pimpinan'
                    ? 'Verified'
                    : 'Pending';
            }

            DB::table('permintaan')->where('id', $permintaanId)->update([
                'prioritas'         => $prioritas,
                'catatan'           => $catatanBaru,
                'status_permintaan' => $statusBaru,
            ]);

            $ringkasan = implode('; ', $perubahan);
            AlurPermintaan::catatLog(
                $permintaanId, (int) $user->id,
                $mode === 'revisi' ? 'Revisi' : 'Edit',
                $ringkasan
            );

            // ── Notifikasi ──────────────────────────────────────
            $nomor = $p->nomor_permintaan;

            if ($statusBaru === 'Pending') {
                AlurPermintaan::notifikasiKeRole(
                    1,
                    $mode === 'revisi' ? 'Revisi Permintaan Dikirim Ulang' : 'Permintaan Diubah User',
                    "Permintaan $nomor " .
                    ($mode === 'revisi' ? 'telah direvisi oleh ' : 'diubah oleh ') .
                    "{$user->nama_lengkap} dan menunggu verifikasi Anda. Perubahan: $ringkasan.",
                    $permintaanId
                );
            } elseif (AlurPermintaan::butuhPimpinan($prioritas)) {
                AlurPermintaan::notifikasiKeRole(
                    3,
                    'Revisi Dikirim Ulang',
                    "Permintaan $nomor telah direvisi oleh {$user->nama_lengkap} dan " .
                    "menunggu persetujuan Anda. Perubahan: $ringkasan.",
                    $permintaanId
                );
            } else {
                // Prioritas diturunkan saat revisi → tidak perlu Pimpinan, langsung siap.
                AlurPermintaan::terbitkanQrJikaSiap($permintaanId);
                AlurPermintaan::notifikasiKeRole(
                    1,
                    'Permintaan Siap Didistribusikan',
                    "Permintaan $nomor telah direvisi dan siap diproses (Scan Checkout & Outbound).",
                    $permintaanId
                );
                AlurPermintaan::notifikasi(
                    (int) $user->id,
                    'Update Status Permintaan',
                    "Revisi permintaan $nomor diterima dan siap diambil. " .
                    "Tunjukkan QR Serah Terima ke Admin.",
                    $permintaanId
                );
            }

            return [
                'ok'      => true,
                'kode'    => 200,
                'message' => $mode === 'revisi'
                    ? "Revisi permintaan $nomor berhasil dikirim ulang."
                    : "Perubahan permintaan $nomor berhasil disimpan.",
                'data'    => ['id' => $permintaanId, 'status_permintaan' => $statusBaru],
            ];
        });
    }

    // ================================================================
    // BATALKAN (hanya status Pending)
    // ================================================================
    public static function batalkan(int $permintaanId, object $user): array
    {
        return DB::transaction(function () use ($permintaanId, $user) {
            $p = DB::table('permintaan')
                ->where('id', $permintaanId)
                ->where('user_id', $user->id)
                ->lockForUpdate()
                ->first();

            if (!$p) {
                return self::gagal('Permintaan tidak ditemukan.', 404);
            }
            if ($p->status_permintaan !== 'Pending') {
                return self::gagal(
                    'Permintaan tidak bisa dibatalkan karena sudah diproses. ' .
                    'Hanya permintaan berstatus Pending yang dapat dibatalkan.',
                    409
                );
            }

            DB::table('permintaan')->where('id', $permintaanId)
                ->update(['status_permintaan' => 'Cancelled']);

            AlurPermintaan::catatLog(
                $permintaanId, (int) $user->id, 'Batal',
                'Permintaan dibatalkan oleh pemohon.'
            );

            AlurPermintaan::notifikasiKeRole(
                1,
                'Permintaan Dibatalkan',
                "Permintaan {$p->nomor_permintaan} dibatalkan oleh {$user->nama_lengkap}.",
                $permintaanId
            );

            return [
                'ok'      => true,
                'kode'    => 200,
                'message' => "Permintaan {$p->nomor_permintaan} berhasil dibatalkan.",
            ];
        });
    }
}
