import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/services/auth_service.dart';
import 'package:inventori_bank/pages/pimpinan/pimpinan_main_page.dart';

class PimpinanDashboardPage extends StatefulWidget {
  final PimpinanMainPageState? mainPageState;

  const PimpinanDashboardPage({super.key, this.mainPageState});

  @override
  State<PimpinanDashboardPage> createState() =>
      _PimpinanDashboardPageState();
}

class _PimpinanDashboardPageState
    extends State<PimpinanDashboardPage> {
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
    final jabatan = _user['jabatan'] ?? 'Pimpinan';

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
                                    ? nama[0].toUpperCase() : 'P',
                                style: const TextStyle(
                                    color     : Colors.white,
                                    fontSize  : 20,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Halo, $nama 👋',
                                    style: const TextStyle(
                                        color     : Colors.white,
                                        fontSize  : 16,
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(jabatan,
                                    style: const TextStyle(
                                        color  : Colors.white70,
                                        fontSize: 12)),
                              ],
                            )),
                            Stack(children: [
                              const Icon(
                                  Icons.notifications_outlined,
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

                      // ── Alert permintaan menunggu ────────
                      if ((_dash['menunggu_approval'] ?? 0) > 0)
                        GestureDetector(
                          onTap: () =>
                              widget.mainPageState?.goToTab(2),
                          child: Container(
                            width  : double.infinity,
                            margin : const EdgeInsets.only(
                                bottom: 20),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius:
                                  BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFF59E0B)),
                            ),
                            child: Row(children: [
                              const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Color(0xFF92400E)),
                              const SizedBox(width: 10),
                              Expanded(child: Text(
                                '${_dash['menunggu_approval']} permintaan '
                                'menunggu persetujuan Anda. Tap untuk lihat.',
                                style: const TextStyle(
                                    color     : Color(0xFF92400E),
                                    fontWeight: FontWeight.w500),
                              )),
                              const Icon(Icons.chevron_right,
                                  color: Color(0xFF92400E)),
                            ]),
                          ),
                        ),

                      // ── Stat Cards ──────────────────────
                      const Text('Ringkasan Approval',
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
                          _statCard('Total Permintaan',
                              '${_dash['total_permintaan'] ?? 0}',
                              Icons.file_copy_outlined,
                              0xFF1565C0, 0xFFE3F2FD),
                          _statCard('Menunggu',
                              '${_dash['menunggu_approval'] ?? 0}',
                              Icons.hourglass_empty,
                              0xFF92400E, 0xFFFEF3C7),
                          _statCard('Disetujui',
                              '${_dash['sudah_diapprove'] ?? 0}',
                              Icons.check_circle_outline,
                              0xFF065F46, 0xFFD1FAE5),
                          _statCard('Ditolak',
                              '${_dash['sudah_direject'] ?? 0}',
                              Icons.cancel_outlined,
                              0xFF991B1B, 0xFFFEE2E2),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Permintaan menunggu persetujuan ──
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Menunggu Persetujuan',
                            style: TextStyle(
                                fontSize  : 16,
                                fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () =>
                                widget.mainPageState?.goToTab(2),
                            child: const Text('Lihat Semua'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_dash['permintaan_terbaru'] == null ||
                          (_dash['permintaan_terbaru'] as List)
                              .isEmpty)
                        _emptyWidget(
                            'Tidak ada permintaan yang menunggu persetujuan.')
                      else
                        ...(_dash['permintaan_terbaru'] as List)
                            .map((p) => _pendingCard(p)),

                      const SizedBox(height: 20),
                    ],
                  ),
                )),
              ]),
            ),
    );
  }

  // ── Card permintaan pending — tap untuk buka approval ────
  Widget _pendingCard(dynamic p) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke tab Approval dan langsung buka detail
        widget.mainPageState?.goToApprovalDetail(
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
                color       : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.hourglass_empty,
                color: Color(0xFF92400E), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p['nomor_permintaan'] ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                '${p['nama_lengkap'] ?? '-'}'
                '${p['bagian'] != null ? " • ${p['bagian']}" : ""}',
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color       : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Pending',
                    style: TextStyle(
                        color     : Color(0xFF92400E),
                        fontSize  : 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              const Row(children: [
                Text('Beri keputusan',
                    style: TextStyle(
                        fontSize: 10,
                        color   : Color(0xFF92400E))),
                Icon(Icons.chevron_right,
                    size : 13,
                    color: Color(0xFF92400E)),
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
      const Icon(Icons.check_circle_outline,
          size: 48, color: Colors.green),
      const SizedBox(height: 8),
      Text(msg,
          textAlign: TextAlign.center,
          style    : const TextStyle(
              color: Colors.grey, fontSize: 13)),
    ]),
  );
}