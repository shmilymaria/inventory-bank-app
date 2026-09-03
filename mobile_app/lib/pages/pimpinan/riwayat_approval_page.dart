import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/pages/pimpinan/detail_approval_page.dart';

class RiwayatApprovalPage extends StatefulWidget {
  const RiwayatApprovalPage({super.key});
  @override
  State<RiwayatApprovalPage> createState() => _RiwayatApprovalPageState();
}

class _RiwayatApprovalPageState extends State<RiwayatApprovalPage> {
  List<dynamic> _data    = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('/riwayat-approval');
    setState(() {
      _data    = res['data'] ?? [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      appBar: AppBar(
        title          : const Text('Riwayat Approval'),
        backgroundColor: primary,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color    : primary,
              child    : _data.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_outlined,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Belum ada riwayat approval.',
                              style:
                                  TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding    : const EdgeInsets.all(16),
                      itemCount  : _data.length,
                      itemBuilder: (_, i) =>
                          _card(context, _data[i]),
                    ),
            ),
    );
  }

  Widget _card(BuildContext context, dynamic item) {
    final keputusan = item['keputusan'] ?? '';
    final color     = _keputusanColor(keputusan);
    final bg        = _keputusanBg(keputusan);
    final icon      = _keputusanIcon(keputusan);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailApprovalPage(
              permintaanId  : int.parse(
                  item['permintaan_id'].toString()),
              nomorPermintaan: item['nomor_permintaan'] ?? '-',
            ),
          ),
        ).then((_) => _load());
      },
      child: Container(
        margin    : const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color    : Colors.black.withOpacity(0.05),
              blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child  : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Icon keputusan
              Container(
                padding   : const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color       : Color(bg),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Color(color), size: 22),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Nomor + badge
                    Row(children: [
                      Expanded(
                        child: Text(
                          item['nomor_permintaan'] ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize  : 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color       : Color(bg),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text(keputusan,
                            style: TextStyle(
                                color     : Color(color),
                                fontSize  : 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),

                    const SizedBox(height: 6),

                    // Pemohon
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item['nama_pemohon'] ?? '-'}'
                          '${item['bagian'] != null ? " • ${item['bagian']}" : ""}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),

                    const SizedBox(height: 2),

                    // Tanggal
                    Row(children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(
                            item['tanggal_approval'] ?? ''),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ]),

                    const SizedBox(height: 6),

                    // Indikator tap
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Lihat detail',
                            style: TextStyle(
                                fontSize: 11,
                                color   : Color(color))),
                        Icon(Icons.chevron_right,
                            size : 14,
                            color: Color(color)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _keputusanColor(String k) {
    if (k == 'Approved') return 0xFF065F46;
    if (k == 'Rejected') return 0xFF991B1B;
    return 0xFF1E40AF;
  }

  int _keputusanBg(String k) {
    if (k == 'Approved') return 0xFFD1FAE5;
    if (k == 'Rejected') return 0xFFFEE2E2;
    return 0xFFDBEAFE;
  }

  IconData _keputusanIcon(String k) {
    if (k == 'Approved') return Icons.check_circle_outline;
    if (k == 'Rejected') return Icons.cancel_outlined;
    return Icons.refresh;
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/'
             '${dt.month.toString().padLeft(2, '0')}/'
             '${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}