import 'package:flutter/material.dart';

/// Tampilan status permintaan (warna, ikon, teks) di satu tempat supaya
/// Beranda, Riwayat, dan Detail selalu konsisten.
class StatusPermintaan {
  /// Urutan tombol filter di Riwayat (setelah "Semua").
  static const List<String> semua = [
    'Pending', 'Verified', 'Approved', 'Rejected',
    'Revision', 'Distributed', 'Cancelled',
  ];

  static int warna(String s) => const {
    'Pending'    : 0xFF92400E,
    'Verified'   : 0xFF155E75,
    'Approved'   : 0xFF065F46,
    'Rejected'   : 0xFF991B1B,
    'Revision'   : 0xFF1E40AF,
    'Distributed': 0xFF5B21B6,
    'Cancelled'  : 0xFF374151,
  }[s] ?? 0xFF64748B;

  static int latar(String s) => const {
    'Pending'    : 0xFFFEF3C7,
    'Verified'   : 0xFFCFFAFE,
    'Approved'   : 0xFFD1FAE5,
    'Rejected'   : 0xFFFEE2E2,
    'Revision'   : 0xFFDBEAFE,
    'Distributed': 0xFFEDE9FE,
    'Cancelled'  : 0xFFE5E7EB,
  }[s] ?? 0xFFF1F5F9;

  static IconData ikon(String s) => const {
    'Pending'    : Icons.hourglass_empty,
    'Verified'   : Icons.verified_outlined,
    'Approved'   : Icons.check_circle_outline,
    'Rejected'   : Icons.cancel_outlined,
    'Revision'   : Icons.refresh,
    'Distributed': Icons.local_shipping_outlined,
    'Cancelled'  : Icons.block,
  }[s] ?? Icons.circle_outlined;

  /// Keterangan status yang menyesuaikan prioritas
  /// (Verified artinya beda untuk Penting vs Normal/Mendesak).
  static String keterangan(String s, {String? prioritas}) {
    switch (s) {
      case 'Pending':
        return 'Menunggu verifikasi Admin';
      case 'Verified':
        return prioritas == 'Penting'
            ? 'Menunggu persetujuan Pimpinan'
            : 'Disetujui Admin — siap diambil';
      case 'Approved':
        return 'Disetujui Pimpinan — siap diambil';
      case 'Rejected':
        return 'Ditolak';
      case 'Revision':
        return 'Perlu direvisi';
      case 'Distributed':
        return 'Barang telah diserahkan';
      case 'Cancelled':
        return 'Dibatalkan';
      default:
        return s;
    }
  }
}

/// Ketentuan prioritas — ditampilkan saat User memilih prioritas supaya
/// tahu mana yang tepat. Nama prioritas mengikuti database
/// (Normal / Mendesak / Penting).
class InfoPrioritas {
  final String nama;
  final String subjudul;
  final String keterangan;
  final String alur;
  final bool   catatanWajib;
  final Color  warna;

  const InfoPrioritas({
    required this.nama,
    required this.subjudul,
    required this.keterangan,
    required this.alur,
    required this.catatanWajib,
    required this.warna,
  });

  static const List<InfoPrioritas> daftar = [
    InfoPrioritas(
      nama        : 'Normal',
      subjudul    : 'Rutin / Stok Aman',
      keterangan  : 'Kebutuhan rutin dengan stok yang masih aman.',
      alur        : 'Diproses oleh Admin (tanpa persetujuan Pimpinan).',
      catatanWajib: false,
      warna       : Colors.green,
    ),
    InfoPrioritas(
      nama        : 'Mendesak',
      subjudul    : 'Butuh Hari Ini',
      keterangan  : 'Stok habis mendadak atau lonjakan operasional.',
      alur        : 'Diproses oleh Admin (tanpa persetujuan Pimpinan).',
      catatanWajib: true,
      warna       : Colors.amber,
    ),
    InfoPrioritas(
      nama        : 'Penting',
      subjudul    : 'Kebutuhan Khusus',
      keterangan  : 'Di luar rutinitas atau untuk meningkatkan operasional.',
      alur        : 'Butuh persetujuan Pimpinan.',
      catatanWajib: true,
      warna       : Colors.red,
    ),
  ];

  static InfoPrioritas cari(String nama) =>
      daftar.firstWhere((p) => p.nama == nama, orElse: () => daftar.first);

  /// Catatan wajib untuk Mendesak & Penting, opsional untuk Normal.
  static bool wajibCatatan(String nama) => cari(nama).catatanWajib;
}
