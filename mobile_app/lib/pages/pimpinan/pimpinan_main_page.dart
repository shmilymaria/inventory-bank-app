import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/pages/pimpinan/pimpinan_dashboard_page.dart';
import 'package:inventori_bank/pages/pimpinan/riwayat_approval_page.dart';
import 'package:inventori_bank/pages/pimpinan/approval_page.dart';
import 'package:inventori_bank/pages/pimpinan/pimpinan_notifikasi_page.dart';
import 'package:inventori_bank/pages/pimpinan/pimpinan_profil_page.dart';

class PimpinanMainPage extends StatefulWidget {
  const PimpinanMainPage({super.key});
  @override
  State<PimpinanMainPage> createState() => PimpinanMainPageState();
}

// State public agar bisa diakses dari dashboard
class PimpinanMainPageState extends State<PimpinanMainPage> {
  int _idx = 0;

  // Key untuk mengakses ApprovalPage
  final GlobalKey<ApprovalPageState> _approvalKey =
      GlobalKey<ApprovalPageState>();

  // Navigasi ke tab tertentu
  void goToTab(int index) {
    setState(() => _idx = index);
  }

  // Navigasi ke Approval dan buka detail permintaan tertentu
  void goToApprovalDetail(int permintaanId, String nomorPermintaan) {
    setState(() => _idx = 2); // index 2 = Approval (tengah)
    Future.delayed(const Duration(milliseconds: 300), () {
      _approvalKey.currentState?.bukaDetail(
          permintaanId, nomorPermintaan);
    });
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      PimpinanDashboardPage(mainPageState: this), // index 0 — Beranda
      const RiwayatApprovalPage(),                // index 1 — Riwayat
      ApprovalPage(key: _approvalKey),            // index 2 — Approval (tengah)
      const PimpinanNotifikasiPage(),             // index 3 — Notifikasi
      const PimpinanProfilPage(),                 // index 4 — Profil
    ];
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex       : _idx,
        onTap              : (i) => setState(() => _idx = i),
        selectedItemColor  : primary,
        unselectedItemColor: Colors.grey,
        type               : BottomNavigationBarType.fixed,
        selectedLabelStyle : const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 11),
        items: [
          const BottomNavigationBarItem(
              icon      : Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label     : 'Beranda'),
          const BottomNavigationBarItem(
              icon      : Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label     : 'Riwayat'),
          // Tombol Approval di tengah — lebih besar
          BottomNavigationBarItem(
              icon: Container(
                width : 48,
                height: 48,
                decoration: BoxDecoration(
                  color    : primary,
                  shape    : BoxShape.circle,
                  boxShadow: [BoxShadow(
                      color    : primary.withOpacity(0.4),
                      blurRadius: 10,
                      offset   : const Offset(0, 4))],
                ),
                child: const Icon(Icons.approval,
                    color: Colors.white, size: 26),
              ),
              label: 'Approval'),
          const BottomNavigationBarItem(
              icon      : Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label     : 'Notifikasi'),
          const BottomNavigationBarItem(
              icon      : Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label     : 'Profil'),
        ],
      ),
    );
  }
}