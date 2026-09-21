import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/widgets/barcode_scanner_page.dart';

class TambahBarangBaruPage extends StatefulWidget {
  /// Kalau halaman ini dibuka gara-gara scan yang tidak dikenali,
  /// kode itu langsung diisikan otomatis ke field kode barang.
  final String? kodeAwal;
  const TambahBarangBaruPage({super.key, this.kodeAwal});

  @override
  State<TambahBarangBaruPage> createState() => _TambahBarangBaruPageState();
}

class _TambahBarangBaruPageState extends State<TambahBarangBaruPage> {
  final _namaCtrl         = TextEditingController();
  final _kodeCtrl         = TextEditingController();
  final _satuanCtrl       = TextEditingController();
  final _stokMinimumCtrl  = TextEditingController(text: '5');
  final _deskripsiCtrl    = TextEditingController();

  List<dynamic> _kategoriList = [];
  int?          _kategoriId;
  bool          _loadingKategori = true;
  bool          _generating      = false;
  bool          _menyimpan       = false;
  bool          _kodeDigenerate  = false; // true kalau kode berasal dari generate, bukan scan fisik

  @override
  void initState() {
    super.initState();
    if (widget.kodeAwal != null) _kodeCtrl.text = widget.kodeAwal!;
    _loadKategori();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _kodeCtrl.dispose();
    _satuanCtrl.dispose();
    _stokMinimumCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadKategori() async {
    setState(() => _loadingKategori = true);
    final res = await ApiService.get('/admin/kategori');
    setState(() {
      _kategoriList   = res['success'] == true ? (res['data'] ?? []) : [];
      _loadingKategori = false;
    });
  }

  Future<void> _scanKodeFisik() async {
    final kode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage(
        title   : 'Scan Barcode Barang',
        subtitle: 'Arahkan kamera ke barcode di kemasan barang',
      )),
    );
    if (kode != null && kode.isNotEmpty) {
      setState(() {
        _kodeCtrl.text    = kode;
        _kodeDigenerate   = false;
      });
    }
  }

  Future<void> _generateKode() async {
    setState(() => _generating = true);
    final res = await ApiService.get('/admin/barang/generate-kode');
    setState(() => _generating = false);

    if (res['success'] == true) {
      setState(() {
        _kodeCtrl.text   = res['data']['kode_barang'].toString();
        _kodeDigenerate  = true;
      });
    } else if (mounted) {
      _snack(res['message'] ?? 'Gagal generate kode.', isError: true);
    }
  }

  Future<void> _simpan() async {
    if (_namaCtrl.text.trim().isEmpty) {
      _snack('Nama barang wajib diisi.', isError: true);
      return;
    }
    if (_kategoriId == null) {
      _snack('Kategori wajib dipilih.', isError: true);
      return;
    }
    if (_kodeCtrl.text.trim().isEmpty) {
      _snack('Kode/barcode barang wajib diisi (scan atau generate).', isError: true);
      return;
    }
    if (_satuanCtrl.text.trim().isEmpty) {
      _snack('Satuan wajib diisi (contoh: pcs, box, rim).', isError: true);
      return;
    }

    setState(() => _menyimpan = true);
    final res = await ApiService.post('/admin/barang', {
      'kategori_id'  : _kategoriId,
      'nama_barang'  : _namaCtrl.text.trim(),
      'kode_barang'  : _kodeCtrl.text.trim(),
      'satuan'       : _satuanCtrl.text.trim(),
      'stok_minimum' : int.tryParse(_stokMinimumCtrl.text.trim()) ?? 0,
      'deskripsi'    : _deskripsiCtrl.text.trim(),
    });
    setState(() => _menyimpan = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _snack(res['message'] ?? 'Barang berhasil ditambahkan.');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context, res['data']);
    } else {
      _snack(res['message'] ?? 'Gagal menambahkan barang.', isError: true);
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
        title          : const Text('Tambah Barang Baru'),
        backgroundColor: primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          TextField(
            controller: _namaCtrl,
            decoration: InputDecoration(
              labelText : 'Nama Barang',
              hintText  : 'Contoh: Kertas HVS A4 80gr',
              border    : OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),

          _loadingKategori
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
              : DropdownButtonFormField<int>(
                  value     : _kategoriId,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border   : OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: _kategoriList.map<DropdownMenuItem<int>>((k) =>
                      DropdownMenuItem(
                        value: int.parse(k['id'].toString()),
                        child: Text(k['nama_kategori']?.toString() ?? ''),
                      )).toList(),
                  onChanged: (v) => setState(() => _kategoriId = v),
                ),
          const SizedBox(height: 14),

          Row(children: [
            Expanded(
              child: TextField(
                controller: _satuanCtrl,
                decoration: InputDecoration(
                  labelText: 'Satuan',
                  hintText : 'pcs, box, rim...',
                  border   : OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller  : _stokMinimumCtrl,
                keyboardType: TextInputType.number,
                decoration  : InputDecoration(
                  labelText: 'Stok Minimum',
                  border   : OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          TextField(
            controller: _deskripsiCtrl,
            maxLines  : 2,
            decoration: InputDecoration(
              labelText: 'Deskripsi (opsional)',
              border   : OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Kode / Barcode Barang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            'Punya barcode fisik di kemasan (misal beli dari toko)? Scan langsung. '
            'Kalau barang ini keluaran bank sendiri (belum ada barcode), pakai Generate Otomatis.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _kodeCtrl,
            readOnly  : true,
            decoration: InputDecoration(
              labelText : 'Kode Barang',
              hintText  : 'Belum diisi',
              border    : OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled    : true,
              fillColor : Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scanKodeFisik,
                icon     : const Icon(Icons.qr_code_scanner, size: 18),
                label    : const Text('Scan Fisik'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _generating ? null : _generateKode,
                icon     : _generating
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 18),
                label    : const Text('Generate Otomatis'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ]),

          // ── Preview barcode Code128 kalau di-generate ───────
          if (_kodeDigenerate && _kodeCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width  : double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(children: [
                const Text('Barcode barang ini (belum ada barcode fisik):',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                BarcodeWidget(
                  barcode: Barcode.code128(),
                  data   : _kodeCtrl.text,
                  width  : double.infinity,
                  height : 90,
                  drawText: true,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  'Screenshot gambar ini lalu print & tempel di kemasan/tempat '
                  'penyimpanan barang, supaya bisa discan lagi nanti saat Checkout '
                  'atau Audit/Opname.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 28),

          ElevatedButton.icon(
            onPressed: _menyimpan ? null : _simpan,
            icon     : _menyimpan
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan Barang'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }
}