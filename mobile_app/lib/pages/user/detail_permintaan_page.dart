import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';

class DetailPermintaanPage extends StatefulWidget {
  final int    permintaanId;
  final String nomorPermintaan;

  const DetailPermintaanPage({
    super.key,
    required this.permintaanId,
    required this.nomorPermintaan,
  });

  @override
  State<DetailPermintaanPage> createState() =>
      _DetailPermintaanPageState();
}

class _DetailPermintaanPageState extends State<DetailPermintaanPage> {
  Map<String, dynamic> _data = {};
  bool                 _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('/permintaan/${widget.permintaanId}');
    setState(() {
      _data    = res['data'] ?? {};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    final permintaan = _data['permintaan'];
    final items      = _data['detail_items'] as List? ?? [];
    final approval   = _data['approval'];

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : Text(widget.nomorPermintaan,
            style: const TextStyle(fontSize: 15)),
        backgroundColor: primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color    : primary,
              child    : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child  : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Status Bar ──────────────────────────
                    if (permintaan != null)
                      _statusBanner(
                          permintaan['status_permintaan'] ?? ''),

                    const SizedBox(height: 16),

                    // ── Info Permintaan ─────────────────────
                    if (permintaan != null)
                      _infoCard(permintaan),

                    const SizedBox(height: 16),

                    // ── Daftar Barang ───────────────────────
                    _itemsCard(items),

                    const SizedBox(height: 16),

                    // ── Hasil Approval ──────────────────────
                    _approvalCard(approval),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Status Banner ────────────────────────────────────────
  Widget _statusBanner(String status) {
    final color = _statusColor(status);
    final bg    = _statusBg(status);
    final icon  = _statusIcon(status);
    final label = _statusLabel(status);

    return Container(
      width  : double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color       : Color(bg),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Color(color).withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          padding   : const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color       : Color(color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Color(color), size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Status Permintaan',
              style: TextStyle(
                  fontSize: 11, color: Color(color))),
          Text(label,
              style: TextStyle(
                  fontSize  : 16,
                  fontWeight: FontWeight.bold,
                  color     : Color(color))),
        ]),
      ]),
    );
  }

  // ── Info Permintaan ──────────────────────────────────────
  Widget _infoCard(dynamic p) => _card(
    title: 'Informasi Permintaan',
    icon : Icons.description_outlined,
    child: Column(children: [
      _infoRow('Nomor', p['nomor_permintaan'] ?? '-'),
      _divider(),
      _infoRow('Tanggal',
          _formatDate(p['tanggal_permintaan'] ?? '')),
      _divider(),
      _infoRow('Prioritas', p['prioritas'] ?? '-',
          valueWidget: _prioritasBadge(p['prioritas'] ?? '')),
      if ((p['catatan'] ?? '').toString().isNotEmpty) ...[
        _divider(),
        _infoRow('Catatan', p['catatan'] ?? '-'),
      ],
    ]),
  );

  // ── Daftar Item Barang ───────────────────────────────────
  Widget _itemsCard(List items) => _card(
    title: 'Barang yang Diminta (${items.length} item)',
    icon : Icons.shopping_cart_outlined,
    child: items.isEmpty
        ? const Center(
            child: Text('Tidak ada item.',
                style: TextStyle(color: Colors.grey)))
        : Column(
            children: items.asMap().entries.map((e) {
              final item = e.value;
              return Container(
                margin    : EdgeInsets.only(
                    top: e.key == 0 ? 0 : 10),
                padding   : const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color       : const Color(AppConstants.bgColor),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.grey.shade200),
                ),
                child: Row(children: [
                  Container(
                    padding   : const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color       : const Color(
                          AppConstants.primaryLightColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                        Icons.inventory_2_outlined,
                        size : 18,
                        color: Color(AppConstants.primaryColor)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['nama_barang'] ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize  : 13)),
                      const SizedBox(height: 2),
                      Text(item['nama_kategori'] ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              color   : Colors.grey)),
                      if ((item['keterangan'] ?? '')
                          .toString()
                          .isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(item['keterangan'],
                            style: const TextStyle(
                                fontSize  : 11,
                                color     : Colors.grey,
                                fontStyle : FontStyle.italic)),
                      ],
                    ],
                  )),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item['jumlah']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize  : 18,
                            color     : Color(
                                AppConstants.primaryColor)),
                      ),
                      Text(item['satuan'] ?? '',
                          style: const TextStyle(
                              fontSize: 11,
                              color   : Colors.grey)),
                    ],
                  ),
                ]),
              );
            }).toList(),
          ),
  );

  // ── Hasil Approval ───────────────────────────────────────
  Widget _approvalCard(dynamic approval) => _card(
    title: 'Hasil Approval',
    icon : Icons.verified_outlined,
    child: approval == null
        ? const Row(children: [
            Icon(Icons.hourglass_empty,
                color: Colors.orange, size: 20),
            SizedBox(width: 10),
            Text('Menunggu keputusan Pimpinan.',
                style: TextStyle(color: Colors.grey)),
          ])
        : Column(children: [

            // Keputusan
            Row(children: [
              Container(
                padding   : const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _keputusanBg(
                      approval['keputusan'] ?? ''),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _keputusanIcon(approval['keputusan'] ?? ''),
                  color: _keputusanColor(
                      approval['keputusan'] ?? ''),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(approval['keputusan'] ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize  : 15,
                          color     : _keputusanColor(
                              approval['keputusan'] ?? ''))),
                  Text('oleh ${approval['nama_pimpinan'] ?? '-'}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ]),

            const SizedBox(height: 12),

            _infoRow('Tanggal Approval',
                _formatDate(
                    approval['tanggal_approval'] ?? '')),

            if ((approval['catatan_approval'] ?? '')
                .toString()
                .isNotEmpty) ...[
              _divider(),
              _infoRow('Catatan',
                  approval['catatan_approval'] ?? '-'),
            ],
          ]),
  );

  // ── Shared Widgets ───────────────────────────────────────
  Widget _card({
    required String   title,
    required IconData icon,
    required Widget   child,
  }) =>
      Container(
        width     : double.infinity,
        padding   : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color    : Colors.black.withOpacity(0.05),
              blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon,
                  color: const Color(AppConstants.primaryColor),
                  size : 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const Divider(height: 20),
            child,
          ],
        ),
      );

  Widget _infoRow(String label, String value,
      {Widget? valueWidget}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child  : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey)),
            ),
            Expanded(
              child: valueWidget ??
                  Text(value,
                      style: const TextStyle(
                          fontSize  : 13,
                          fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  Widget _divider() =>
      const Divider(height: 1, color: Color(0xFFF1F5F9));

  Widget _prioritasBadge(String p) {
    Color color;
    if (p == 'Mendesak') {
      color = Colors.red.shade600;
    } else if (p == 'Penting') {
      color = Colors.orange.shade600;
    } else {
      color = Colors.grey;
    }
    return Row(children: [
      Icon(Icons.flag, color: color, size: 14),
      const SizedBox(width: 4),
      Text(p, style: TextStyle(
          color: color, fontWeight: FontWeight.w600,
          fontSize: 13)),
    ]);
  }

  // ── Status helpers ───────────────────────────────────────
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

  String _statusLabel(String s) {
    const m = {
      'Pending'    : 'Menunggu Persetujuan',
      'Approved'   : 'Disetujui',
      'Rejected'   : 'Ditolak',
      'Revision'   : 'Perlu Revisi',
      'Distributed': 'Barang Didistribusikan',
    };
    return m[s] ?? s;
  }

  Color _keputusanColor(String k) {
    if (k == 'Approved') return Colors.green.shade700;
    if (k == 'Rejected') return Colors.red.shade700;
    return Colors.blue.shade700;
  }

  Color _keputusanBg(String k) {
    if (k == 'Approved') return Colors.green.shade50;
    if (k == 'Rejected') return Colors.red.shade50;
    return Colors.blue.shade50;
  }

  IconData _keputusanIcon(String k) {
    if (k == 'Approved') return Icons.check_circle;
    if (k == 'Rejected') return Icons.cancel;
    return Icons.refresh;
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/'
             '${dt.month.toString().padLeft(2, '0')}/'
             '${dt.year}  '
             '${dt.hour.toString().padLeft(2, '0')}:'
             '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}