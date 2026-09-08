import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/pages/admin/distribusi/proses_distribusi_page.dart';

class DistribusiListPage extends StatefulWidget {
  const DistribusiListPage({super.key});
  @override
  State<DistribusiListPage> createState() => _DistribusiListPageState();
}

class _DistribusiListPageState extends State<DistribusiListPage> {
  List<dynamic> _daftar  = [];
  List<dynamic> _riwayat = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.get('/admin/distribusi/siap'),
      ApiService.get('/admin/distribusi/riwayat'),
    ]);
    setState(() {
      _daftar  = results[0]['success'] == true ? (results[0]['data'] ?? []) : [];
      _riwayat = results[1]['success'] == true ? (results[1]['data'] ?? []) : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : const Text('Distribusi — Checkout & Outbound'),
        backgroundColor: primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child  : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text('Siap Distribusi',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),

                    if (_daftar.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            const Text('Tidak ada permintaan siap distribusi.',
                                style: TextStyle(color: Colors.grey)),
                          ]),
                        ),
                      )
                    else
                      ..._daftar.map((p) => _card(p)),

                    const SizedBox(height: 24),

                    const Text('Riwayat Checkout & Outbound Terbaru',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 10),
                    _riwayatList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _riwayatList() {
    if (_riwayat.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Belum ada riwayat.',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    return Column(
      children: _riwayat.map((r) {
        final isOutbound = r['tipe'] == 'Outbound';
        final waktu       = DateTime.tryParse(r['waktu'].toString());
        final waktuStr    = waktu != null
            ? DateFormat('dd MMM yyyy, HH:mm').format(waktu) : '-';

        return Container(
          margin    : const EdgeInsets.only(bottom: 10),
          padding   : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isOutbound ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isOutbound ? Icons.local_shipping_outlined : Icons.fact_check_outlined,
                color: isOutbound ? Colors.blue.shade700 : Colors.orange.shade700,
                size : 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(r['nomor_permintaan']?.toString() ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 12.5)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isOutbound ? Colors.blue.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(r['tipe']?.toString() ?? '',
                          style: TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w700,
                              color: isOutbound ? Colors.blue.shade700 : Colors.orange.shade700)),
                    ),
                  ]),
                  const SizedBox(height: 2),
                  Text(r['keterangan']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('oleh ${r['nama_admin'] ?? '-'} · $waktuStr',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ]),
        );
      }).toList(),
    );
  }

  Widget _card(dynamic p) {
    final totalItem   = int.parse(p['total_item'].toString());
    final sudahScan   = int.parse(p['item_sudah_scan'].toString());
    final selesaiChk  = p['checkout_selesai'] == true || p['checkout_selesai'] == 1;
    final tanggal     = DateTime.tryParse(p['tanggal_permintaan'].toString());
    final tglStr      = tanggal != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(tanggal) : '-';

    return Container(
      margin    : const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProsesDistribusiPage(permintaanId: p['id']),
          ));
          _load();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(p['nomor_permintaan']?.toString() ?? '-',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              _prioritasBadge(p['prioritas']?.toString() ?? ''),
            ]),
            const SizedBox(height: 4),
            Text('${p['nama_lengkap'] ?? '-'} · ${p['bagian'] ?? '-'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 2),
            Text(tglStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),

            const SizedBox(height: 12),

            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value : totalItem == 0 ? 0 : sudahScan / totalItem,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: selesaiChk ? Colors.green : const Color(AppConstants.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('$sudahScan/$totalItem item',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selesaiChk ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  selesaiChk ? Icons.qr_code_scanner : Icons.fact_check_outlined,
                  size : 14,
                  color: selesaiChk ? Colors.green.shade700 : Colors.orange.shade700,
                ),
                const SizedBox(width: 5),
                Text(
                  selesaiChk
                      ? 'Checkout selesai — siap Scan Outbound'
                      : 'Perlu Scan Checkout',
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600,
                      color: selesaiChk ? Colors.green.shade700 : Colors.orange.shade700),
                ),
              ]),
            ),
          ]),
        ),
      ),
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