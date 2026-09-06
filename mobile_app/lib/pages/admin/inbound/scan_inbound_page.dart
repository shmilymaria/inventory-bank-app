import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/widgets/barcode_scanner_page.dart';

class ScanInboundPage extends StatefulWidget {
  const ScanInboundPage({super.key});
  @override
  State<ScanInboundPage> createState() => _ScanInboundPageState();
}

class _ScanInboundPageState extends State<ScanInboundPage> {
  dynamic _barang;               // hasil pencarian barang dari scan
  bool    _mencari      = false;
  bool    _mengirim     = false;
  List<dynamic> _riwayat = [];
  bool    _loadingRiwayat = true;

  final TextEditingController _jumlahCtrl     = TextEditingController();
  final TextEditingController _keteranganCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRiwayat();
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRiwayat() async {
    setState(() => _loadingRiwayat = true);
    final res = await ApiService.get('/admin/inbound/riwayat');
    if (res['success'] == true) {
      setState(() {
        _riwayat        = res['data'] ?? [];
        _loadingRiwayat = false;
      });
    } else {
      setState(() => _loadingRiwayat = false);
    }
  }

  Future<void> _mulaiScan() async {
    final kode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage(
        title   : 'Scan Barang Masuk',
        subtitle: 'Arahkan kamera ke barcode/QR pada kemasan barang',
      )),
    );

    if (kode == null || kode.isEmpty) return;
    await _cariBarang(kode);
  }

  Future<void> _cariBarang(String kode) async {
    setState(() {
      _mencari = true;
      _barang  = null;
    });

    final res = await ApiService.get('/admin/barang/$kode');

    setState(() => _mencari = false);

    if (res['success'] == true) {
      setState(() {
        _barang = res['data'];
        _jumlahCtrl.clear();
        _keteranganCtrl.clear();
      });
    } else {
      if (!mounted) return;
      _snack(res['message'] ?? 'Barang tidak ditemukan.', isError: true);
    }
  }

  Future<void> _submitInbound() async {
    final jumlahText = _jumlahCtrl.text.trim();
    if (jumlahText.isEmpty || int.tryParse(jumlahText) == null ||
        int.parse(jumlahText) <= 0) {
      _snack('Masukkan jumlah barang masuk yang valid.', isError: true);
      return;
    }

    setState(() => _mengirim = true);

    final res = await ApiService.post('/admin/inbound', {
      'kode_barang': _barang['kode_barang'].toString(),
      'jumlah'     : int.parse(jumlahText),
      'keterangan' : _keteranganCtrl.text.trim(),
    });

    setState(() => _mengirim = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _snack(res['message'] ?? 'Stok berhasil ditambahkan.');
      setState(() => _barang = null);
      _loadRiwayat();
    } else {
      _snack(res['message'] ?? 'Gagal menambah stok.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior       : SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin  : const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : const Text('Scan Inbound'),
        backgroundColor: primary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRiwayat,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child  : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Tombol Scan ────────────────────────────────
              ElevatedButton.icon(
                onPressed: _mencari ? null : _mulaiScan,
                icon     : _mencari
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.qr_code_scanner),
                label: Text(_mencari ? 'Mencari barang...' : 'Scan Barang',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 16),

              // ── Kartu hasil scan / form input jumlah ────────
              if (_barang != null) _formInboundCard(),

              if (_barang == null) ...[
                const SizedBox(height: 30),
                Icon(Icons.qr_code_2_outlined,
                    size: 70, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('Belum ada barang di-scan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500)),
              ],

              const SizedBox(height: 24),

              // ── Riwayat inbound terbaru ─────────────────────
              const Text('Riwayat Inbound Terbaru',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              _riwayatList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formInboundCard() {
    final stok   = int.parse(_barang['stok'].toString());
    final satuan = _barang['satuan']?.toString() ?? '';
    final gambar = AppConstants.resolveImageUrl(_barang['gambar']?.toString());

    return Container(
      padding   : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(AppConstants.primaryColor).withOpacity(0.25)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width : 60, height: 60,
              child : gambar.isNotEmpty
                  ? Image.network(gambar, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImg())
                  : _placeholderImg(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_barang['nama_barang']?.toString() ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(_barang['kode_barang']?.toString() ?? '',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('Stok saat ini: $stok $satuan',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color   : Color(AppConstants.primaryColor))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => setState(() => _barang = null),
          ),
        ]),

        const Divider(height: 24),

        TextField(
          controller : _jumlahCtrl,
          keyboardType: TextInputType.number,
          decoration : InputDecoration(
            labelText : 'Jumlah Masuk',
            hintText  : 'Contoh: 20',
            suffixText: satuan,
            border    : OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _keteranganCtrl,
          decoration: InputDecoration(
            labelText: 'Keterangan (opsional)',
            hintText : 'Contoh: Pembelian dari supplier ABC',
            border   : OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: _mengirim ? null : _submitInbound,
          icon     : _mengirim
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add_box_outlined),
          label: Text(_mengirim ? 'Menyimpan...' : 'Tambah Stok'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }

  Widget _placeholderImg() => Container(
    color: const Color(AppConstants.primaryLightColor),
    alignment: Alignment.center,
    child: const Icon(Icons.inventory_2_outlined,
        size: 26, color: Color(AppConstants.primaryColor)),
  );

  Widget _riwayatList() {
    if (_loadingRiwayat) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_riwayat.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Belum ada riwayat inbound.',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    return Column(
      children: _riwayat.map((r) {
        final tanggal = DateTime.tryParse(r['created_at'].toString());
        final tglStr  = tanggal != null
            ? DateFormat('dd MMM yyyy, HH:mm').format(tanggal)
            : '-';

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
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_downward_rounded,
                  color: Colors.green.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['nama_barang']?.toString() ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    '+${r['jumlah']} ${r['satuan'] ?? ''} · $tglStr',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text('${r['stok_sesudah']}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor))),
          ]),
        );
      }).toList(),
    );
  }
}