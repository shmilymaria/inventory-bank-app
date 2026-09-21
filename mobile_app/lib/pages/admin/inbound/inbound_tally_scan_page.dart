import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/widgets/barcode_scanner_page.dart';
import 'package:inventori_bank/pages/admin/inbound/tambah_barang_baru_page.dart';

class InboundTallyScanPage extends StatefulWidget {
  final dynamic barang; // hasil dari katalog: id, kode_barang, nama_barang, stok, satuan, gambar, dst
  const InboundTallyScanPage({super.key, required this.barang});

  @override
  State<InboundTallyScanPage> createState() => _InboundTallyScanPageState();
}

class _InboundTallyScanPageState extends State<InboundTallyScanPage> {
  int    _tally      = 0;
  bool   _mengecek   = false;
  bool   _mengirim   = false;
  final List<String> _logWaktu = []; // jam tiap scan sukses, untuk ditampilkan

  final TextEditingController _keteranganCtrl = TextEditingController();

  String get _kodeBarangDipilih => widget.barang['kode_barang'].toString();
  String get _namaBarangDipilih => widget.barang['nama_barang']?.toString() ?? '-';

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final kode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => BarcodeScannerPage(
        title   : 'Scan: $_namaBarangDipilih',
        subtitle: 'Scan barcode di kemasan satu per satu',
      )),
    );
    if (kode == null || kode.isEmpty) return;

    if (kode == _kodeBarangDipilih) {
      // Cocok — tambah tally
      setState(() {
        _tally++;
        _logWaktu.insert(0, TimeOfDay.now().format(context));
      });
      return;
    }

    // Tidak cocok — cek dulu ini punya barang lain atau belum terdaftar sama sekali
    await _tanganiScanTidakCocok(kode);
  }

  Future<void> _tanganiScanTidakCocok(String kode) async {
    setState(() => _mengecek = true);
    final res = await ApiService.get('/admin/barang/$kode');
    setState(() => _mengecek = false);

    if (!mounted) return;

    if (res['success'] == true) {
      // Kode ini terdaftar, tapi punya barang LAIN
      final namaLain = res['data']?['nama_barang']?.toString() ?? '-';
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title  : const Text('Barcode Tidak Cocok'),
          content: Text(
            'Barcode ini terdaftar untuk barang lain: "$namaLain".\n\n'
            'Pastikan Anda men-scan kemasan "$_namaBarangDipilih" yang benar.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    } else {
      // Kode belum terdaftar sama sekali
      final tambah = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title  : const Text('Barcode Belum Terdaftar'),
          content: Text(
            'Kode "$kode" belum terdaftar untuk barang manapun di sistem.\n\n'
            'Kalau ini memang bukan "$_namaBarangDipilih", mungkin Anda scan barang '
            'yang salah. Atau, kalau ini barang baru yang belum pernah didaftarkan, '
            'Anda bisa menambahkannya sekarang.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Coba Scan Lagi'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tambah Sebagai Barang Baru'),
            ),
          ],
        ),
      );

      if (tambah == true && mounted) {
        final barangBaru = await Navigator.push(context, MaterialPageRoute(
          builder: (_) => TambahBarangBaruPage(kodeAwal: kode),
        ));
        if (barangBaru != null && mounted) {
          // Ganti konteks halaman ini ke barang yang baru dibuat
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => InboundTallyScanPage(barang: barangBaru),
          ));
        }
      }
    }
  }

  Future<void> _selesai() async {
    if (_tally <= 0) {
      _snack('Scan minimal 1 barang dulu sebelum menyimpan.', isError: true);
      return;
    }

    setState(() => _mengirim = true);
    final res = await ApiService.post('/admin/inbound', {
      'kode_barang': _kodeBarangDipilih,
      'jumlah'     : _tally,
      'keterangan' : _keteranganCtrl.text.trim(),
    });
    setState(() => _mengirim = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _snack(res['message'] ?? 'Stok berhasil ditambahkan.');
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context);
    } else {
      _snack(res['message'] ?? 'Gagal menyimpan.', isError: true);
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
    final stokSaatIni = widget.barang['stok']?.toString() ?? '0';
    final satuan      = widget.barang['satuan']?.toString() ?? '';
    final gambar      = AppConstants.resolveImageUrl(widget.barang['gambar']?.toString());

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : const Text('Hitung Stok Masuk'),
        backgroundColor: primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

          // ── Info barang ────────────────────────────────
          Container(
            padding   : const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60, height: 60,
                  child: gambar.isNotEmpty
                      ? Image.network(gambar, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_namaBarangDipilih,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('Kode: $_kodeBarangDipilih',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('Stok saat ini: $stokSaatIni $satuan',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600,
                          color: Color(AppConstants.primaryColor))),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Tally counter besar ─────────────────────────
          Container(
            width  : double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withOpacity(0.2)),
            ),
            child: Column(children: [
              Text('$_tally',
                  style: const TextStyle(
                      fontSize: 56, fontWeight: FontWeight.bold, color: primary)),
              Text('unit ter-scan',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ]),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: _mengecek ? null : _scan,
            icon     : _mengecek
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.qr_code_scanner),
            label: Text(_mengecek ? 'Memeriksa...' : 'Scan Barcode'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _keteranganCtrl,
            decoration: InputDecoration(
              labelText: 'Keterangan (opsional)',
              hintText : 'Contoh: Pembelian dari supplier ABC',
              border   : OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: (_mengirim || _tally <= 0) ? null : _selesai,
            icon     : _mengirim
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_outline),
            label: Text(_mengirim ? 'Menyimpan...' : 'Selesai & Simpan ($_tally unit)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: primary, width: 1.5),
            ),
          ),

          if (_logWaktu.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Log Scan Sesi Ini',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...List.generate(_logWaktu.length, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Icon(Icons.check_circle, size: 15, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text('Unit #${_logWaktu.length - i} — ${_logWaktu[i]}',
                    style: const TextStyle(fontSize: 12.5)),
              ]),
            )),
          ],
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(AppConstants.primaryLightColor),
    alignment: Alignment.center,
    child: const Icon(Icons.inventory_2_outlined,
        size: 26, color: Color(AppConstants.primaryColor)),
  );
}