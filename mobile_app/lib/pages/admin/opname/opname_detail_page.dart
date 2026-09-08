import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';

class OpnameDetailPage extends StatefulWidget {
  final int opnameId;
  const OpnameDetailPage({super.key, required this.opnameId});

  @override
  State<OpnameDetailPage> createState() => _OpnameDetailPageState();
}

class _OpnameDetailPageState extends State<OpnameDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('/admin/opname/${widget.opnameId}');
    setState(() {
      _data    = res['success'] == true ? res['data'] : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_data == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: primary),
        body  : const Center(child: Text('Data tidak ditemukan.')),
      );
    }

    final sesi     = _data!['sesi'];
    final items    = (_data!['items'] as List?) ?? [];
    final totalSelisih = _data!['total_selisih'] ?? 0;
    final mulai    = DateTime.tryParse(sesi['tanggal_mulai'].toString());
    final selesai  = DateTime.tryParse(sesi['tanggal_selesai']?.toString() ?? '');
    final fmt      = DateFormat('dd MMM yyyy, HH:mm');

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : const Text('Laporan Opname'),
        backgroundColor: primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Container(
            width  : double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _row('Dilakukan oleh', sesi['nama_admin']?.toString() ?? '-'),
              _row('Mulai', mulai != null ? fmt.format(mulai) : '-'),
              _row('Selesai', selesai != null ? fmt.format(selesai) : '-'),
              _row('Total Barang Dicek', '${items.length}'),
              _row('Total Selisih', '$totalSelisih',
                  valueColor: totalSelisih > 0 ? Colors.red : Colors.green),
              if ((sesi['catatan'] ?? '').toString().isNotEmpty)
                _row('Catatan', sesi['catatan'].toString()),
            ]),
          ),

          const SizedBox(height: 20),
          const Text('Detail per Barang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),

          ...items.map((it) {
            final selisih = int.parse(it['selisih'].toString());
            final cocok   = selisih == 0;
            return Container(
              margin    : const EdgeInsets.only(bottom: 10),
              padding   : const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: cocok ? Colors.grey.shade200 : Colors.red.shade200),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text(it['nama_barang']?.toString() ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cocok ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cocok ? 'Sesuai' : (selisih > 0 ? '+$selisih' : '$selisih'),
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: cocok ? Colors.green.shade700 : Colors.red.shade700),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  'Kode: ${it['kode_barang']} · Sistem: ${it['stok_sistem']} · '
                  'Fisik: ${it['stok_fisik']} ${it['satuan']}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
                if ((it['keterangan'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(it['keterangan'].toString(),
                      style: TextStyle(
                          fontSize: 11.5, fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600)),
                ],
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child  : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 140,
        child: Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ),
      Expanded(
        child: Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: valueColor)),
      ),
    ]),
  );
}