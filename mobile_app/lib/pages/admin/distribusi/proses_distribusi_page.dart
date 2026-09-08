import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/widgets/barcode_scanner_page.dart';

class ProsesDistribusiPage extends StatefulWidget {
  final int permintaanId;
  const ProsesDistribusiPage({super.key, required this.permintaanId});

  @override
  State<ProsesDistribusiPage> createState() => _ProsesDistribusiPageState();
}

class _ProsesDistribusiPageState extends State<ProsesDistribusiPage> {
  Map<String, dynamic> _data    = {};
  bool                  _loading = true;
  bool                  _memproses = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('/admin/distribusi/${widget.permintaanId}');
    if (res['success'] == true) {
      setState(() {
        _data    = res['data'];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (mounted) {
        _snack(res['message'] ?? 'Gagal memuat data.', isError: true);
      }
    }
  }

  // ── Scan Checkout ──────────────────────────────────────────
  Future<void> _scanCheckout() async {
    final kode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage(
        title   : 'Scan Checkout',
        subtitle: 'Scan barcode fisik barang yang akan diserahkan',
      )),
    );
    if (kode == null || kode.isEmpty) return;

    setState(() => _memproses = true);
    final res = await ApiService.post(
      '/admin/distribusi/${widget.permintaanId}/checkout',
      {'kode_scan': kode},
    );
    setState(() => _memproses = false);

    if (!mounted) return;

    if (res['success'] == true) {
      final sudahAda = res['data']?['sudah_ada'] == true;
      _snack(res['message'] ?? 'Berhasil.', isError: false, warn: sudahAda);
      await _load();
    } else {
      _snack(res['message'] ?? 'Barang tidak cocok.', isError: true);
    }
  }

  // ── Scan Outbound ──────────────────────────────────────────
  Future<void> _scanOutbound() async {
    final kode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage(
        title   : 'Scan Outbound',
        subtitle: 'Scan QR dari HP User sebagai bukti serah terima',
      )),
    );
    if (kode == null || kode.isEmpty) return;

    setState(() => _memproses = true);
    final res = await ApiService.post(
      '/admin/distribusi/${widget.permintaanId}/outbound',
      {'qr_code': kode},
    );
    setState(() => _memproses = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _snack(res['message'] ?? 'Distribusi selesai.', isError: false);
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);
    } else {
      _snack(res['message'] ?? 'QR tidak valid.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false, bool warn = false}) {
    final color = isError
        ? Colors.red.shade700
        : (warn ? Colors.orange.shade700 : Colors.green.shade700);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: color,
      behavior       : SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin  : const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final permintaan = _data['permintaan'];
    final items      = (_data['items'] as List?) ?? [];
    final semuaSiap  = _data['semua_sudah_checkout'] == true;

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title: Text(permintaan?['nomor_permintaan']?.toString() ?? '-'),
        backgroundColor: primary,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Info pemohon ─────────────────────────────
            Container(
              width  : double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.person_outline,
                      size: 18, color: Color(AppConstants.primaryColor)),
                  const SizedBox(width: 8),
                  Text(permintaan?['nama_lengkap']?.toString() ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
                const SizedBox(height: 4),
                Text('${permintaan?['bagian'] ?? '-'} · ${permintaan?['jabatan'] ?? '-'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ),

            const SizedBox(height: 16),

            const Text('Checklist Barang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),

            ...items.map((item) => _itemChecklistRow(item)),

            const SizedBox(height: 16),

            // ── Tombol Scan Checkout ───────────────────────
            ElevatedButton.icon(
              onPressed: (_memproses || semuaSiap) ? null : _scanCheckout,
              icon     : const Icon(Icons.qr_code_scanner),
              label    : Text(semuaSiap
                  ? 'Semua Item Sudah Dicek ✓'
                  : 'Scan Checkout'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: semuaSiap ? Colors.grey.shade400 : primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            // ── Tombol Scan Outbound ───────────────────────
            ElevatedButton.icon(
              onPressed: (_memproses || !semuaSiap) ? null : _scanOutbound,
              icon     : _memproses
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.local_shipping_outlined),
              label: Text(_memproses ? 'Memproses...' : 'Scan Outbound (Konfirmasi Serah Terima)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: semuaSiap ? Colors.green.shade600 : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            if (!semuaSiap) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Selesaikan Scan Checkout semua item dulu sebelum Outbound.',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _itemChecklistRow(dynamic item) {
    final sudah = item['sudah_checkout'] == true;

    return Container(
      margin    : const EdgeInsets.only(bottom: 10),
      padding   : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: sudah ? Colors.green.shade200 : Colors.grey.shade200),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Icon(
          sudah ? Icons.check_circle : Icons.radio_button_unchecked,
          color: sudah ? Colors.green : Colors.grey.shade400,
          size : 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['nama_barang']?.toString() ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(item['kode_barang']?.toString() ?? '',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Text('${item['jumlah']} ${item['satuan'] ?? ''}',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColor))),
      ]),
    );
  }
}