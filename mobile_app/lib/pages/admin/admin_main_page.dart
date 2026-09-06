import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/pages/admin/admin_dashboard_page.dart';
import 'package:inventori_bank/pages/admin/admin_profil_page.dart';

/// Shell navigasi untuk role Admin di mobile.
///
/// CATATAN: ini versi awal (fase Inbound). Tab "Distribusi" (Checkout +
/// Outbound) dan "Audit" akan ditambahkan ke _pages & items di bawah pada
/// fase berikutnya — struktur di sini sudah didesain supaya tinggal
/// menambah 1 baris di masing-masing tanpa mengubah logic lain.
class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});
  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _idx = 0;

  final List<Widget> _pages = const [
    AdminDashboardPage(), // index 0 — Beranda
    AdminProfilPage(),    // index 1 — Profil
  ];

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
        items: const [
          BottomNavigationBarItem(
              icon      : Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label     : 'Beranda'),
          BottomNavigationBarItem(
              icon      : Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label     : 'Profil'),
        ],
      ),
    );
  }
}