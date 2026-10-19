import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/pages/user/detail_permintaan_page.dart';
import 'package:inventori_bank/pages/pimpinan/detail_approval_page.dart';
import 'package:inventori_bank/pages/admin/verifikasi/verifikasi_detail_page.dart';
import 'package:inventori_bank/pages/admin/distribusi/proses_distribusi_page.dart';

/// Deep link notifikasi: saat notifikasi diketuk, langsung buka halaman
/// detail permintaan yang bersangkutan — halamannya menyesuaikan peran:
///
///   User     → Detail Permintaan (Riwayat)
///   Pimpinan → Detail Approval
///   Admin    → Proses Distribusi bila permintaan sudah siap diproses,
///              selain itu Verifikasi Permintaan
class NotifikasiNavigator {
  /// Mengembalikan true bila notifikasi punya tujuan dan halamannya dibuka.
  static Future<bool> buka(
    BuildContext context,
    Map<String, dynamic> notifikasi,
    int roleId,
  ) async {
    final rawId = notifikasi['permintaan_id'];
    if (rawId == null) return false; // notifikasi umum tanpa tautan

    final id    = int.tryParse(rawId.toString());
    if (id == null) return false;
    final nomor = notifikasi['nomor_permintaan']?.toString() ?? '';

    final Widget tujuan;
    if (roleId == AppConstants.roleAdmin) {
      final siap = notifikasi['siap_distribusi'] == true ||
          notifikasi['siap_distribusi'] == 1;
      tujuan = siap
          ? ProsesDistribusiPage(permintaanId: id)
          : VerifikasiDetailPage(permintaanId: id, nomorPermintaan: nomor);
    } else if (roleId == AppConstants.rolePimpinan) {
      tujuan = DetailApprovalPage(permintaanId: id, nomorPermintaan: nomor);
    } else {
      tujuan = DetailPermintaanPage(permintaanId: id, nomorPermintaan: nomor);
    }

    await Navigator.push(context, MaterialPageRoute(builder: (_) => tujuan));
    return true;
  }
}
