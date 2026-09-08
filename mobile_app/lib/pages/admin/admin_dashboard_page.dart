import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/auth_service.dart';
import 'package:inventori_bank/pages/admin/inbound/scan_inbound_page.dart';
import 'package:inventori_bank/pages/admin/distribusi/distribusi_list_page.dart';
import 'package:inventori_bank/pages/admin/opname/opname_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
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

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);
    final nama    = _user['nama_lengkap']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      body: SingleChildScrollView(
        child: Column(children: [

          // ── Header sambutan ────────────────────────────────
          Container(
            width  : double.infinity,
            color  : primary,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            child  : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selamat datang,',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 2),
                Text(nama.isNotEmpty ? nama : 'Admin',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Admin — Mode Lapangan',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Menu Cepat',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount : 2,
                  shrinkWrap     : true,
                  physics        : const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing : 12,
                  childAspectRatio: 1.15,
                  children: [
                    _menuCard(
                      icon : Icons.move_to_inbox_outlined,
                      label: 'Scan Inbound',
                      desc : 'Tambah stok barang masuk',
                      color: Colors.green,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ScanInboundPage())),
                    ),
                    _menuCard(
                      icon : Icons.fact_check_outlined,
                      label: 'Scan Checkout',
                      desc : 'Validasi pengeluaran barang',
                      color: Colors.orange,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const DistribusiListPage())),
                    ),
                    _menuCard(
                      icon : Icons.qr_code_scanner,
                      label: 'Scan Outbound',
                      desc : 'Konfirmasi distribusi ke User',
                      color: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const DistribusiListPage())),
                    ),
                    _menuCard(
                      icon : Icons.fact_check,
                      label: 'Audit / Opname',
                      desc : 'Cocokkan stok fisik vs sistem',
                      color: Colors.purple,
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const OpnamePage())),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String   label,
    required String   desc,
    required Color    color,
    VoidCallback?      onTap,
    bool               segeraHadir = false,
  }) {
    return Opacity(
      opacity: segeraHadir ? 0.55 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: segeraHadir
              ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content : Text('$label — Segera hadir 🚧'),
                    behavior: SnackBarBehavior.floating,
                  ))
              : onTap,
          child: Container(
            padding   : const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                if (segeraHadir) ...[
                  const SizedBox(height: 4),
                  Text('Segera hadir',
                      style: TextStyle(
                          fontSize: 10, color: color,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}