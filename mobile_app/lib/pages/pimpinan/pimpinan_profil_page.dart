import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/auth_service.dart';
import 'package:inventori_bank/pages/login_page.dart';

class PimpinanProfilPage extends StatefulWidget {
  const PimpinanProfilPage({super.key});
  @override
  State<PimpinanProfilPage> createState() => _PimpinanProfilPageState();
}

class _PimpinanProfilPageState extends State<PimpinanProfilPage> {
  Map<String, dynamic> _user = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await AuthService.getUserData();
    setState(() => _user = u);
  }

  Future<void> _logout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Konfirmasi Logout'),
        content: const Text('Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style    : ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);
    final nama    = _user['nama_lengkap'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title          : const Text('Profil Saya'),
        backgroundColor: primary,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(children: [

          // ── Header ──────────────────────────────────────
          Container(
            width  : double.infinity,
            color  : primary,
            padding: const EdgeInsets.only(
                top: 10, bottom: 30, left: 20, right: 20),
            child  : Column(children: [
              CircleAvatar(
                radius         : 40,
                backgroundColor: Colors.white24,
                child: Text(
                  nama.isNotEmpty ? nama[0].toUpperCase() : 'P',
                  style: const TextStyle(
                      fontSize  : 34,
                      fontWeight: FontWeight.bold,
                      color     : Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(nama,
                  style: const TextStyle(
                      fontSize  : 18,
                      fontWeight: FontWeight.bold,
                      color     : Colors.white)),
              const SizedBox(height: 4),
              Container(
                padding   : const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color       : Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _user['role_name'] ?? 'Pimpinan',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Info Profil ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child  : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8)],
              ),
              child: Column(children: [
                _row(Icons.person_outline, 'Username',
                    _user['username'] ?? '-'),
                _divider(),
                _row(Icons.business_outlined, 'Bagian',
                    _user['bagian'] ?? '-'),
                _divider(),
                _row(Icons.work_outline, 'Jabatan',
                    _user['jabatan'] ?? '-'),
                _divider(),
                _row(Icons.email_outlined, 'Email',
                    _user['email'] ?? '-'),
                _divider(),
                _row(Icons.phone_outlined, 'No. HP',
                    _user['nomor_hp'] ?? '-'),
              ]),
            ),
          ),

          const SizedBox(height: 24),

          // ── Tombol Logout ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child  : ElevatedButton.icon(
              onPressed: _logout,
              icon     : const Icon(Icons.logout),
              label    : const Text('Logout',
                  style: TextStyle(
                      fontSize  : 16,
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                minimumSize    : const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child  : Row(children: [
      Icon(icon,
          color: const Color(AppConstants.primaryColor), size: 20),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      )),
    ]),
  );

  Widget _divider() => const Divider(height: 1, indent: 50);
}