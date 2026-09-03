import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/pages/pimpinan/detail_approval_page.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});
  @override
  State<ApprovalPage> createState() => ApprovalPageState();
}

// State public agar bisa dipanggil dari PimpinanMainPage
class ApprovalPageState extends State<ApprovalPage> {
  List<dynamic> _data    = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('/approval');
    setState(() {
      _data    = res['data'] ?? [];
      _loading = false;
    });
  }

  // Dipanggil dari PimpinanMainPage saat tap di dashboard
  void bukaDetail(int permintaanId, String nomorPermintaan) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailApprovalPage(
          permintaanId   : permintaanId,
          nomorPermintaan: nomorPermintaan,
        ),
      ),
    ).then((_) => _load());
  }

  Future<void> _showApprovalDialog(dynamic p) async {
    String keputusan    = 'Approved';
    final catatanCtrl   = TextEditingController();
    bool  submitting    = false;

    await showModalBottomSheet(
      context            : context,
      isScrollControlled : true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left  : 20, right: 20, top: 20,
            bottom:
                MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // Handle bar
            Container(
              width : 40, height: 4,
              decoration: BoxDecoration(
                  color       : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),

            const SizedBox(height: 16),

            Text('Keputusan untuk ${p['nomor_permintaan']}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${p['nama_lengkap']}'
              '${p['bagian'] != null ? " • ${p['bagian']}" : ""}',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // Pilih keputusan
            Row(
              children: ['Approved', 'Rejected', 'Revision']
                  .map((k) => Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4),
                        child  : GestureDetector(
                          onTap: () =>
                              setModal(() => keputusan = k),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            decoration: BoxDecoration(
                              color: keputusan == k
                                  ? _keputusanColor(k)
                                      .withOpacity(0.12)
                                  : Colors.grey.shade100,
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: keputusan == k
                                    ? _keputusanColor(k)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(children: [
                              Icon(
                                _keputusanIcon(k),
                                color: keputusan == k
                                    ? _keputusanColor(k)
                                    : Colors.grey,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(k,
                                  style: TextStyle(
                                    fontSize  : 11,
                                    fontWeight: FontWeight.w600,
                                    color     : keputusan == k
                                        ? _keputusanColor(k)
                                        : Colors.grey,
                                  )),
                            ]),
                          ),
                        ),
                      )))
                  .toList(),
            ),

            const SizedBox(height: 16),

            // Catatan
            TextField(
              controller : catatanCtrl,
              maxLines   : 3,
              decoration : const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText : 'Tambahkan catatan untuk pemohon...',
                border   : OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Tombol submit
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setModal(() => submitting = true);
                      final body = {
                        'keputusan'       : keputusan,
                        'catatan_approval': catatanCtrl.text.trim(),
                      };
                      final res = await ApiService.post(
                          '/approval/${p['id']}', body);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        _snack(
                          res['success'] == true
                              ? res['message'] ?? 'Berhasil'
                              : res['message'] ?? 'Gagal',
                          isError: res['success'] != true,
                        );
                        _load();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _keputusanColor(keputusan),
                minimumSize    : const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: submitting
                  ? const SizedBox(
                      width : 20, height: 20,
                      child : CircularProgressIndicator(
                          color      : Colors.white,
                          strokeWidth: 2))
                  : Text(
                      'Konfirmasi $keputusan',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize  : 15),
                    ),
            ),
          ]),
        ),
      ),
    );
    catatanCtrl.dispose();
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: isError
          ? Colors.red.shade700
          : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Approval Permintaan'
          '${_data.isNotEmpty ? " (${_data.length})" : ""}',
        ),
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
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64, color: Colors.green),
                          SizedBox(height: 12),
                          Text(
                            'Tidak ada permintaan yang perlu disetujui.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding    : const EdgeInsets.all(16),
                      itemCount  : _data.length,
                      itemBuilder: (_, i) {
                        final p = _data[i];
                        return _card(p);
                      },
                    ),
            ),
    );
  }

  Widget _card(dynamic p) => Container(
    margin    : const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color    : Colors.black.withOpacity(0.05),
          blurRadius: 8)],
    ),
    child: Column(children: [

      // Tap card → buka detail
      GestureDetector(
        onTap: () => bukaDetail(
          int.parse(p['id'].toString()),
          p['nomor_permintaan'] ?? '-',
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child  : Row(children: [
            Container(
              padding   : const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color       : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_outlined,
                  color: Color(0xFF92400E), size: 22),
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
                Text('${p['nama_lengkap']}',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black87)),
                Text(
                  '${p['bagian'] ?? '-'}'
                  '${p['jabatan'] != null ? " • ${p['jabatan']}" : ""}',
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _prioritasBadge(p['prioritas'] ?? ''),
                const SizedBox(height: 6),
                const Row(children: [
                  Text('Detail',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey)),
                  Icon(Icons.chevron_right,
                      size: 13, color: Colors.grey),
                ]),
              ],
            ),
          ]),
        ),
      ),

      const Divider(height: 1),

      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child  : Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            _formatDate(p['tanggal_permintaan'] ?? ''),
            style: const TextStyle(
                fontSize: 12, color: Colors.grey),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _showApprovalDialog(p),
            style    : ElevatedButton.styleFrom(
              minimumSize: const Size(130, 36),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Beri Keputusan',
                style: TextStyle(fontSize: 12)),
          ),
        ]),
      ),
    ]),
  );

  Widget _prioritasBadge(String p) {
    Color bg, fg;
    if (p == 'Mendesak') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
    } else if (p == 'Penting') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    }
    return Container(
      padding   : const EdgeInsets.symmetric(
          horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(p,
          style: TextStyle(
              color     : fg,
              fontSize  : 11,
              fontWeight: FontWeight.bold)),
    );
  }

  Color _keputusanColor(String k) {
    if (k == 'Approved') return Colors.green.shade600;
    if (k == 'Rejected') return Colors.red.shade600;
    return Colors.blue.shade600;
  }

  IconData _keputusanIcon(String k) {
    if (k == 'Approved') return Icons.check_circle_outline;
    if (k == 'Rejected') return Icons.cancel_outlined;
    return Icons.refresh;
  }

  String _formatDate(String raw) {
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