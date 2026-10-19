import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/cart_service.dart';
import 'package:inventori_bank/pages/user/user_dashboard_page.dart';
import 'package:inventori_bank/pages/user/riwayat_permintaan_page.dart';
import 'package:inventori_bank/pages/user/ajukan_permintaan_page.dart';
import 'package:inventori_bank/pages/user/user_notifikasi_page.dart';
import 'package:inventori_bank/pages/user/user_profil_page.dart';

class UserMainPage extends StatefulWidget {
  const UserMainPage({super.key});
  @override
  State<UserMainPage> createState() => UserMainPageState();
}

// State dibuat public agar bisa diakses dari dashboard
class UserMainPageState extends State<UserMainPage> {
  int _idx = 0;

  // Key untuk mengakses halaman-halaman tab dari luar
  final GlobalKey<UserDashboardPageState> _berandaKey =
      GlobalKey<UserDashboardPageState>();
  final GlobalKey<RiwayatPermintaanPageState> _riwayatKey =
      GlobalKey<RiwayatPermintaanPageState>();
  final GlobalKey<UserNotifikasiPageState> _notifKey =
      GlobalKey<UserNotifikasiPageState>();
  final GlobalKey<AjukanPermintaanPageState> _ajukanKey =
      GlobalKey<AjukanPermintaanPageState>();

  // Navigasi ke tab tertentu dari luar
  void goToTab(int index) {
    setState(() => _idx = index);
    _segarkanTab(index);
  }

  // Beranda → Riwayat dengan filter status tertentu ('' = Semua)
  void goToRiwayat(String status) {
    setState(() => _idx = 1);
    _riwayatKey.currentState?.setFilter(status);
  }

  // Beranda → Ajukan dengan kelompok kategori tertentu
  // ('ATK' / 'Barang Cetakan' / 'Barang Lainnya' / null = Semua)
  void goToAjukan({String? kelompok}) {
    setState(() => _idx = 2);
    _ajukanKey.currentState?.setKelompok(kelompok);
  }

  // Navigasi ke Riwayat dan buka detail permintaan tertentu
  void goToRiwayatDetail(int permintaanId, String nomorPermintaan) {
    setState(() => _idx = 1); // index 1 = Riwayat
    _riwayatKey.currentState?.setFilter('');
    // Beri jeda agar widget sudah ter-render
    Future.delayed(const Duration(milliseconds: 300), () {
      _riwayatKey.currentState?.bukaDetail(
          permintaanId, nomorPermintaan);
    });
  }

  // Data Beranda & Riwayat disegarkan setiap kali tabnya dibuka lagi
  void _segarkanTab(int index) {
    if (index == 0) _berandaKey.currentState?.muat();
    if (index == 1) _riwayatKey.currentState?.muat();
    if (index == 3) _notifKey.currentState?.muat();
  }

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    CartService.instance.muat(); // keranjang milik akun yang sedang login
    _pages = [
      UserDashboardPage(key: _berandaKey, mainPageState: this), // index 0 — Beranda
      RiwayatPermintaanPage(key: _riwayatKey),  // index 1 — Riwayat
      AjukanPermintaanPage(key: _ajukanKey),    // index 2 — Ajukan (tengah)
      UserNotifikasiPage(key: _notifKey),       // index 3 — Notifikasi
      const UserProfilPage(),                   // index 4 — Profil
    ];
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      body: IndexedStack(index: _idx, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex       : _idx,
        onTap              : (i) {
          setState(() => _idx = i);
          _segarkanTab(i);
        },
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
          // Tombol Ajukan di tengah — lebih besar
          BottomNavigationBarItem(
              icon: Container(
                width : 48,
                height: 48,
                decoration: BoxDecoration(
                  color       : primary,
                  shape       : BoxShape.circle,
                  boxShadow   : [BoxShadow(
                      color    : primary.withOpacity(0.4),
                      blurRadius: 10,
                      offset   : const Offset(0, 4))],
                ),
                child: const Icon(Icons.add,
                    color: Colors.white, size: 28),
              ),
              label: 'Ajukan'),
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