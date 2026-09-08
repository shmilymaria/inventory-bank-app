import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/auth_service.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/pages/admin/inbound/scan_inbound_page.dart';
import 'package:inventori_bank/pages/admin/distribusi/distribusi_list_page.dart';
import 'package:inventori_bank/pages/admin/opname/opname_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic> _user    = {};
  Map<String, dynamic> _stats   = {};
  bool                  _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      AuthService.getUserData(),
      ApiService.get('/dashboard'),
    ]);

    setState(() {
      _user    = results[0] as Map<String, dynamic>;
      _stats   = (results[1] as Map)['success'] == true
          ? Map<String, dynamic>.from((results[1] as Map)['data'])
          : {};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);
    final nama    = _user['nama_lengkap']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child  : Column(children: [

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

                  // ── Ringkasan Hari Ini ───────────────────────
                  const Text('Ringkasan Hari Ini',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),

                  _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _ringkasanGrid(),

                  const SizedBox(height: 24),

                  // ── Menu Cepat ───────────────────────────────
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
      ),
    );
  }

  // ── Grid ringkasan (data live dari /api/dashboard) ─────────
  Widget _ringkasanGrid() {
    final stokMenipis = _stats['barang_stok_menipis'] ?? 0;
    final barangHabis = _stats['barang_habis'] ?? 0;
    final siapDistribusi = _stats['siap_distribusi'] ?? 0;
    final opnameJalan = _stats['opname_berlangsung'] == true;
    final inboundHariIni = _stats['inbound_hari_ini'] ?? 0;

    return Column(children: [
      Row(children: [
        Expanded(child: _statCard(
          icon : Icons.warning_amber_rounded,
          label: 'Stok Menipis',
          value: '$stokMenipis',
          color: Colors.orange,
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          icon : Icons.remove_shopping_cart_outlined,
          label: 'Stok Habis',
          value: '$barangHabis',
          color: Colors.red,
        )),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _statCard(
          icon : Icons.local_shipping_outlined,
          label: 'Siap Distribusi',
          value: '$siapDistribusi',
          color: Colors.blue,
        )),
        const SizedBox(width: 10),
        Expanded(child: _statCard(
          icon : Icons.move_to_inbox_outlined,
          label: 'Inbound Hari Ini',
          value: '$inboundHariIni',
          color: Colors.green,
        )),
      ]),
      if (opnameJalan) ...[
        const SizedBox(height: 10),
        Container(
          width  : double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Row(children: [
            Icon(Icons.timelapse, color: Colors.purple.shade700, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ada sesi Opname yang belum diselesaikan.',
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: Colors.purple.shade800),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const OpnamePage())),
              child: const Text('Lanjutkan'),
            ),
          ]),
        ),
      ],
    ]);
  }

  Widget _statCard({
    required IconData icon,
    required String   label,
    required String   value,
    required MaterialColor color,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color.shade700, size: 19),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 17)),
            Text(label, style: TextStyle(
                fontSize: 10.5, color: Colors.grey.shade600)),
          ],
        ),
      ),
    ]),
  );

  Widget _menuCard({
    required IconData icon,
    required String   label,
    required String   desc,
    required Color    color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
            ],
          ),
        ),
      ),
    );
  }
}