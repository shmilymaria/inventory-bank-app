import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/pages/user/detail_permintaan_page.dart';

class RiwayatPermintaanPage extends StatefulWidget {
  const RiwayatPermintaanPage({super.key});
  @override
  State<RiwayatPermintaanPage> createState() =>
      RiwayatPermintaanPageState();
}

// State dibuat public agar bisa dipanggil dari UserMainPage
class RiwayatPermintaanPageState
    extends State<RiwayatPermintaanPage> {
  List<dynamic> _data    = [];
  String        _filter  = '';
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ep  = _filter.isEmpty
        ? '/permintaan'
        : '/permintaan?status=$_filter';
    final res = await ApiService.get(ep);
    setState(() {
      _data    = res['data'] ?? [];
      _loading = false;
    });
  }

  // Dipanggil dari UserMainPage saat tap permintaan di dashboard
  void bukaDetail(int permintaanId, String nomorPermintaan) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPermintaanPage(
          permintaanId   : permintaanId,
          nomorPermintaan: nomorPermintaan,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      appBar: AppBar(
        title          : const Text('Riwayat Permintaan'),
        backgroundColor: primary,
        automaticallyImplyLeading: false,
      ),
      body: Column(children: [

        // ── Filter chips ──────────────────────────────────
        Container(
          color  : Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child  : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                '', 'Pending', 'Approved',
                'Rejected', 'Revision', 'Distributed',
              ].map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child  : FilterChip(
                      label   : Text(s.isEmpty ? 'Semua' : s),
                      selected: _filter == s,
                      onSelected: (_) {
                        setState(() => _filter = s);
                        _load();
                      },
                      selectedColor  : const Color(
                          AppConstants.primaryLightColor),
                      checkmarkColor : primary,
                      labelStyle     : TextStyle(
                        color     : _filter == s
                            ? primary : Colors.grey,
                        fontWeight: _filter == s
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize  : 13,
                      ),
                    ),
                  ))
                  .toList(),
            ),
          ),
        ),

        // ── List ─────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  color    : primary,
                  child    : _data.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size : 60,
                                  color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Belum ada permintaan.',
                                  style: TextStyle(
                                      color: Colors.grey)),
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
        ),
      ]),
    );
  }

  Widget _card(BuildContext context, dynamic p) {
    final status = p['status_permintaan'] ?? '';
    final color  = _statusColor(status);
    final bg     = _statusBg(status);
    final icon   = _statusIcon(status);

    return GestureDetector(
      onTap: () => bukaDetail(
        int.parse(p['id'].toString()),
        p['nomor_permintaan'] ?? '-',
      ),
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
          child  : Row(children: [

            Container(
              padding   : const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color       : Color(bg),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Color(color), size: 22),
            ),

            const SizedBox(width: 12),

            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['nomor_permintaan'] ?? '-',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize  : 14)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.flag_outlined,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(p['prioritas'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(_formatDate(
                      p['tanggal_permintaan'] ?? ''),
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ]),
              ],
            )),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color       : Color(bg),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(status,
                      style: TextStyle(
                          color     : Color(color),
                          fontSize  : 11,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Text('Detail',
                      style: TextStyle(
                          fontSize: 11, color: Color(color))),
                  Icon(Icons.chevron_right,
                      size: 14, color: Color(color)),
                ]),
              ],
            ),
          ]),
        ),
      ),
    );
  }

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