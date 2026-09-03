import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/services/auth_service.dart';
import 'package:inventori_bank/pages/user/user_main_page.dart';

class UserDashboardPage extends StatefulWidget {
  // Referensi ke parent agar bisa navigasi antar tab
  final UserMainPageState? mainPageState;

  const UserDashboardPage({super.key, this.mainPageState});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  Map<String, dynamic> _dash = {};
  Map<String, dynamic> _user = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.get('/dashboard'),
      AuthService.getUserData(),
    ]);
    setState(() {
      _dash    = (results[0] as Map<String, dynamic>)['data'] ?? {};
      _user    = results[1] as Map<String, dynamic>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);
    final nama    = _user['nama_lengkap'] ?? '';
    final bagian  = _user['bagian'] ?? '';

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color    : primary,
              child    : CustomScrollView(slivers: [

                // ── AppBar ─────────────────────────────────
                SliverAppBar(
                  expandedHeight: 160,
                  pinned        : true,
                  automaticallyImplyLeading: false,
                  backgroundColor: primary,
                  flexibleSpace : FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(AppConstants.primaryColor),
                            Color(AppConstants.primaryDarkColor),
                          ],
                          begin: Alignment.topLeft,
                          end  : Alignment.bottomRight,
                        ),
                      ),
                      child: SafeArea(child: Padding(
                        padding: const EdgeInsets.all(20),
                        child  : Column(
                          mainAxisAlignment : MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [Row(children: [
                            CircleAvatar(
                              radius         : 24,
                              backgroundColor: Colors.white24,
                              child: Text(
                                nama.isNotEmpty
                                    ? nama[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                    color     : Colors.white,
                                    fontSize  : 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Halo, $nama 👋',
                                    style: const TextStyle(
                                        color     : Colors.white,
                                        fontSize  : 16,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(bagian,
                                    style: const TextStyle(
                                        color  : Colors.white70,
                                        fontSize: 12)),
                              ],
                            )),
                            Stack(children: [
                              const Icon(Icons.notifications_outlined,
                                  color: Colors.white, size: 26),
                              if ((_dash['notifikasi_belum_dibaca']
                                      ?? 0) >
                                  0)
                                Positioned(
                                  right: 0, top: 0,
                                  child: Container(
                                    width : 9, height: 9,
                                    decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle),
                                  ),
                                ),
                            ]),
                          ])],
                        ),
                      )),
                    ),
                  ),
                ),

                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Stat Cards ──────────────────────
                      const Text('Ringkasan Permintaan',
                          style: TextStyle(
                              fontSize  : 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      GridView.count(
                        shrinkWrap      : true,
                        physics         : const NeverScrollableScrollPhysics(),
                        crossAxisCount  : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing : 12,
                        childAspectRatio: 1.6,
                        children: [
                          _statCard('Total',
                              '${_dash['total_permintaan'] ?? 0}',
                              Icons.file_copy_outlined,
                              0xFF1565C0, 0xFFE3F2FD),
                          _statCard('Pending',
                              '${_dash['pending'] ?? 0}',
                              Icons.hourglass_empty,
                              0xFF92400E, 0xFFFEF3C7),
                          _statCard('Approved',
                              '${_dash['approved'] ?? 0}',
                              Icons.check_circle_outline,
                              0xFF065F46, 0xFFD1FAE5),
                          _statCard('Distributed',
                              '${_dash['distributed'] ?? 0}',
                              Icons.local_shipping_outlined,
                              0xFF5B21B6, 0xFFEDE9FE),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Permintaan Terbaru ───────────────
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Permintaan Terbaru',
                              style: TextStyle(
                                  fontSize  : 16,
                                  fontWeight: FontWeight.bold)),
                          // Tombol lihat semua → ke tab Riwayat
                          TextButton(
                            onPressed: () =>
                                widget.mainPageState?.goToTab(1),
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_dash['permintaan_terbaru'] == null ||
                          (_dash['permintaan_terbaru'] as List)
                              .isEmpty)
                        _emptyWidget(
                            'Belum ada permintaan.\n'
                            'Gunakan tombol + di bawah untuk membuat permintaan baru.')
                      else
                        ...(_dash['permintaan_terbaru'] as List)
                            .map((p) => _permintaanCard(p)),

                      const SizedBox(height: 20),
                    ],
                  ),
                )),
              ]),
            ),
    );
  }

  // ── Card permintaan — tap untuk ke detail di tab Riwayat ─
  Widget _permintaanCard(dynamic p) {
    final status = p['status_permintaan'] ?? '';
    final color  = _statusColor(status);
    final bg     = _statusBg(status);
    final icon   = _statusIcon(status);

    return GestureDetector(
      onTap: () {
        // Navigasi ke tab Riwayat dan langsung buka detail
        widget.mainPageState?.goToRiwayatDetail(
          int.parse(p['id'].toString()),
          p['nomor_permintaan'] ?? '-',
        );
      },
      child: Container(
        margin    : const EdgeInsets.only(bottom: 10),
        padding   : const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color    : Colors.black.withOpacity(0.05),
              blurRadius: 8)],
        ),
        child: Row(children: [
          Container(
            padding   : const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color       : Color(bg),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Color(color), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['nomor_permintaan'] ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              Text(p['prioritas'] ?? '',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            ],
          )),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding   : const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color       : Color(bg),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(status,
                    style: TextStyle(
                        color     : Color(color),
                        fontSize  : 11,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Text('Detail',
                    style: TextStyle(
                        fontSize: 10, color: Color(color))),
                Icon(Icons.chevron_right,
                    size: 13, color: Color(color)),
              ]),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _statCard(String title, String value,
      IconData icon, int color, int bg) =>
      Container(
        padding   : const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color    : Colors.black.withOpacity(0.05),
              blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment : MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding   : const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color       : Color(bg),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Color(color), size: 20),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(value,
                  style: TextStyle(
                      fontSize  : 22,
                      fontWeight: FontWeight.bold,
                      color     : Color(color))),
              Text(title,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ],
        ),
      );

  Widget _emptyWidget(String msg) => Container(
    width  : double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.circular(14)),
    child: Column(children: [
      const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
      const SizedBox(height: 8),
      Text(msg,
          textAlign: TextAlign.center,
          style    : const TextStyle(
              color: Colors.grey, fontSize: 13)),
    ]),
  );

  int _statusColor(String s) {
    const m = {
      'Pending'    : 0xFF92400E,
      'Approved'   : 0xFF065F46,
      'Rejected'   : 0xFF991B1B,
      'Revision'   : 0xFF1E40AF,
      'Distributed': 0xFF5B21B6,
    };
    return m[s] ?? 0xFF64748B;
  }

  int _statusBg(String s) {
    const m = {
      'Pending'    : 0xFFFEF3C7,
      'Approved'   : 0xFFD1FAE5,
      'Rejected'   : 0xFFFEE2E2,
      'Revision'   : 0xFFDBEAFE,
      'Distributed': 0xFFEDE9FE,
    };
    return m[s] ?? 0xFFF1F5F9;
  }

  IconData _statusIcon(String s) {
    const m = {
      'Pending'    : Icons.hourglass_empty,
      'Approved'   : Icons.check_circle_outline,
      'Rejected'   : Icons.cancel_outlined,
      'Revision'   : Icons.refresh,
      'Distributed': Icons.local_shipping_outlined,
    };
    return m[s] ?? Icons.circle_outlined;
  }
}