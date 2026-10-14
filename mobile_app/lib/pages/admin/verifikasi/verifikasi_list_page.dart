import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/pages/admin/verifikasi/verifikasi_detail_page.dart';

/// Tahap 1 approval: Admin (bagian umum) memverifikasi permintaan User
/// sebelum diteruskan ke Pimpinan.
class VerifikasiListPage extends StatefulWidget {
  const VerifikasiListPage({super.key});
  @override
  State<VerifikasiListPage> createState() => _VerifikasiListPageState();
}

class _VerifikasiListPageState extends State<VerifikasiListPage> {
  List<dynamic> _menunggu = [];
  List<dynamic> _riwayat  = [];
  bool          _loading  = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.get('/admin/verifikasi'),
      ApiService.get('/admin/verifikasi-riwayat'),
    ]);
    setState(() {
      _menunggu = results[0]['success'] == true ? (results[0]['data'] ?? []) : [];
      _riwayat  = results[1]['success'] == true ? (results[1]['data'] ?? []) : [];
      _loading  = false;
    });
  }

  Future<void> _bukaDetail(dynamic p) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => VerifikasiDetailPage(
        permintaanId   : int.parse(p['id'].toString()),
        nomorPermintaan: p['nomor_permintaan']?.toString() ?? '-',
      ),
    ));
    _load();
  }

  String _fmt(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    return d != null ? DateFormat('dd MMM yyyy, HH:mm').format(d) : '-';
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : const Text('Verifikasi Permintaan'),
        backgroundColor: primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  Row(children: [
                    const Text('Menunggu Verifikasi',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(width: 8),
                    if (_menunggu.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${_menunggu.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  const SizedBox(height: 10),

                  if (_menunggu.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: Column(children: [
                        Icon(Icons.task_alt, size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text('Tidak ada permintaan yang menunggu verifikasi.',
                            style: TextStyle(color: Colors.grey)),
                      ])),
                    )
                  else
                    ..._menunggu.map(_kartuMenunggu),

                  const SizedBox(height: 24),
                  const Text('Riwayat Verifikasi Terbaru',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  _riwayatList(),
                ]),
              ),
            ),
    );
  }

  Widget _kartuMenunggu(dynamic p) {
    final total = p['total_item']?.toString() ?? '0';

    return Container(
      margin    : const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _bukaDetail(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(p['nomor_permintaan']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              _prioritasBadge(p['prioritas']?.toString() ?? ''),
            ]),
            const SizedBox(height: 4),
            Text('${p['nama_lengkap'] ?? '-'} · ${p['bagian'] ?? '-'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(_fmt(p['tanggal_permintaan']),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.inventory_2_outlined, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text('$total jenis barang',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              const Spacer(),
              Text('Periksa',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.orange.shade800)),
              Icon(Icons.chevron_right, size: 18, color: Colors.orange.shade800),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _riwayatList() {
    if (_riwayat.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('Belum ada riwayat verifikasi.',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    return Column(
      children: _riwayat.map((r) {
        final k = r['keputusan']?.toString() ?? '';
        final warna = k == 'Approved'
            ? Colors.green
            : (k == 'Rejected' ? Colors.red : Colors.blue);
        final label = k == 'Approved' ? 'Diteruskan ke Pimpinan' : k;

        return Container(
          margin    : const EdgeInsets.only(bottom: 10),
          padding   : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: warna.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                k == 'Approved'
                    ? Icons.forward_to_inbox
                    : (k == 'Rejected' ? Icons.cancel_outlined : Icons.refresh),
                color: warna.shade700, size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['nomor_permintaan']?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: warna.shade700)),
                const SizedBox(height: 2),
                Text('${r['nama_pemohon'] ?? '-'} · oleh ${r['nama_admin'] ?? '-'} · '
                    '${_fmt(r['tanggal_approval'])}',
                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
              ]),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _prioritasBadge(String p) {
    Color color = Colors.grey;
    if (p == 'Mendesak') color = Colors.red.shade600;
    if (p == 'Penting')  color = Colors.orange.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(p, style: TextStyle(
          fontSize: 10.5, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
