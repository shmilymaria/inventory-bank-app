import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/widgets/barcode_scanner_page.dart';
import 'package:inventori_bank/pages/admin/opname/opname_detail_page.dart';

class OpnamePage extends StatefulWidget {
  const OpnamePage({super.key});
  @override
  State<OpnamePage> createState() => _OpnamePageState();
}

class _OpnamePageState extends State<OpnamePage> {
  Map<String, dynamic>? _sesiAktif; // null = belum ada sesi berjalan
  List<dynamic> _riwayat  = [];
  bool          _loading  = true;
  bool          _memproses = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.get('/admin/opname/aktif'),
      ApiService.get('/admin/opname/riwayat'),
    ]);

    setState(() {
      _sesiAktif = (results[0]['success'] == true) ? results[0]['data'] : null;
      _riwayat   = (results[1]['success'] == true) ? (results[1]['data'] ?? []) : [];
      _loading   = false;
    });
  }

  Future<void> _mulaiSesi() async {
    setState(() => _memproses = true);
    final res = await ApiService.post('/admin/opname/mulai', {});
    setState(() => _memproses = false);

    if (res['success'] == true) {
      setState(() => _sesiAktif = res['data']);
    } else if (mounted) {
      _snack(res['message'] ?? 'Gagal memulai sesi.', isError: true);
    }
  }

  Future<void> _scanBarang() async {
    final opnameId = _sesiAktif?['sesi']?['id'];
    if (opnameId == null) return;

    final kode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage(
        title   : 'Scan Audit Barang',
        subtitle: 'Arahkan kamera ke barcode/QR barang yang dihitung',
      )),
    );
    if (kode == null || kode.isEmpty) return;

    setState(() => _memproses = true);
    final cari = await ApiService.get(
        '/admin/opname/barang/$kode?opname_id=$opnameId');
    setState(() => _memproses = false);

    if (cari['success'] != true) {
      if (mounted) {
        _snack(cari['message'] ?? 'Barang tidak ditemukan.', isError: true);
      }
      return;
    }

    if (!mounted) return;
    await _dialogInputStokFisik(opnameId, cari['data']);
  }

  Future<void> _dialogInputStokFisik(int opnameId, dynamic data) async {
    final barang     = data['barang'];
    final stokLama   = data['stok_fisik_lama'];
    final ketLama    = data['keterangan_lama'];
    final stokCtrl   = TextEditingController(
        text: stokLama != null ? stokLama.toString() : '');
    final ketCtrl    = TextEditingController(text: ketLama?.toString() ?? '');

    final hasilInput = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(barang['nama_barang']?.toString() ?? '-',
            style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kode: ${barang['kode_barang']}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('Stok Sistem: ${barang['stok']} ${barang['satuan']}',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13,
                    color: Color(AppConstants.primaryColor))),
            if (data['sudah_discan'] == true) ...[
              const SizedBox(height: 4),
              Text('Sudah pernah dicek di sesi ini — bisa dikoreksi.',
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
            ],
            const SizedBox(height: 14),
            TextField(
              controller  : stokCtrl,
              autofocus   : true,
              keyboardType: TextInputType.number,
              decoration  : InputDecoration(
                labelText : 'Stok Fisik (hasil hitung manual)',
                suffixText: barang['satuan']?.toString() ?? '',
                border    : const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ketCtrl,
              decoration: const InputDecoration(
                labelText: 'Keterangan (opsional)',
                border   : OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (hasilInput != true) return;
    if (stokCtrl.text.trim().isEmpty || int.tryParse(stokCtrl.text.trim()) == null) {
      _snack('Stok fisik harus diisi dengan angka.', isError: true);
      return;
    }

    setState(() => _memproses = true);
    final res = await ApiService.post('/admin/opname/$opnameId/scan', {
      'kode_barang': barang['kode_barang'],
      'stok_fisik' : int.parse(stokCtrl.text.trim()),
      'keterangan' : ketCtrl.text.trim(),
    });
    setState(() => _memproses = false);

    if (!mounted) return;

    if (res['success'] == true) {
      final selisih = res['data']?['selisih'] ?? 0;
      _snack(res['message'] ?? 'Tersimpan.',
          isError: false, warn: selisih != 0);
      _load();
    } else {
      _snack(res['message'] ?? 'Gagal menyimpan.', isError: true);
    }
  }

  Future<void> _selesaikanSesi() async {
    final opnameId = _sesiAktif?['sesi']?['id'];
    if (opnameId == null) return;

    final totalItem    = _sesiAktif?['total_item'] ?? 0;
    final totalSelisih = _sesiAktif?['total_selisih'] ?? 0;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Selesaikan Sesi Opname?'),
        content: Text(
          'Total $totalItem barang sudah dicek, ditemukan $totalSelisih '
          'selisih.\n\nSetelah diselesaikan, sesi ini akan masuk riwayat '
          'dan tidak bisa discan lagi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Selesaikan'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    setState(() => _memproses = true);
    final res = await ApiService.post('/admin/opname/$opnameId/selesai', {});
    setState(() => _memproses = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _snack(res['message'] ?? 'Sesi selesai.');
      setState(() => _sesiAktif = null);
      _load();
    } else {
      _snack(res['message'] ?? 'Gagal menyelesaikan sesi.', isError: true);
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

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : const Text('Audit / Stock Opname'),
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

                    if (_sesiAktif == null)
                      _kartuMulaiSesi()
                    else
                      _kartuSesiAktif(),

                    const SizedBox(height: 24),

                    const Text('Riwayat Sesi Opname',
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

  Widget _kartuMulaiSesi() => Container(
    width  : double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Column(children: [
      Icon(Icons.fact_check_outlined,
          size: 50, color: Colors.purple.shade300),
      const SizedBox(height: 12),
      const Text('Belum ada sesi opname berjalan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 4),
      Text('Mulai sesi baru untuk mencocokkan stok fisik vs sistem.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _memproses ? null : _mulaiSesi,
        icon     : const Icon(Icons.play_arrow_rounded),
        label    : const Text('Mulai Sesi Opname'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.purple.shade600,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ]),
  );

  Widget _kartuSesiAktif() {
    final sesi          = _sesiAktif!['sesi'];
    final items         = (_sesiAktif!['items'] as List?) ?? [];
    final totalItem     = _sesiAktif!['total_item'] ?? 0;
    final totalSelisih  = _sesiAktif!['total_selisih'] ?? 0;
    final mulai         = DateTime.tryParse(sesi['tanggal_mulai'].toString());
    final mulaiStr      = mulai != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(mulai) : '-';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Container(
        width  : double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(children: [
          Row(children: [
            Icon(Icons.timelapse, color: Colors.purple.shade700, size: 20),
            const SizedBox(width: 8),
            Text('Sesi Berlangsung sejak $mulaiStr',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: Colors.purple.shade800)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _statChip('Item Dicek', '$totalItem', Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _statChip('Selisih Ditemukan', '$totalSelisih',
                totalSelisih > 0 ? Colors.red : Colors.green)),
          ]),
        ]),
      ),

      const SizedBox(height: 14),

      ElevatedButton.icon(
        onPressed: _memproses ? null : _scanBarang,
        icon     : const Icon(Icons.qr_code_scanner),
        label    : const Text('Scan Barang'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: (_memproses || totalItem == 0) ? null : _selesaikanSesi,
        icon     : const Icon(Icons.flag_outlined),
        label    : const Text('Selesaikan Sesi'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),

      const SizedBox(height: 16),

      if (items.isNotEmpty) ...[
        const Text('Barang Dicek Sesi Ini',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ...items.map((it) => _itemRow(it)),
      ],
    ]);
  }

  Widget _statChip(String label, String value, MaterialColor color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(children: [
      Text(value, style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: color.shade700)),
      Text(label, style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600)),
    ]),
  );

  Widget _itemRow(dynamic it) {
    final selisih = int.parse(it['selisih'].toString());
    final cocok   = selisih == 0;

    return Container(
      margin    : const EdgeInsets.only(bottom: 8),
      padding   : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: cocok ? Colors.grey.shade200 : Colors.red.shade200),
      ),
      child: Row(children: [
        Icon(cocok ? Icons.check_circle : Icons.warning_amber_rounded,
            color: cocok ? Colors.green : Colors.red, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it['nama_barang']?.toString() ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12.5)),
              Text('Sistem: ${it['stok_sistem']} · Fisik: ${it['stok_fisik']} ${it['satuan']}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        Text(
          cocok ? 'Sesuai' : (selisih > 0 ? '+$selisih' : '$selisih'),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 12.5,
              color: cocok ? Colors.green.shade700 : Colors.red.shade700),
        ),
      ]),
    );
  }

  Widget _riwayatList() {
    if (_riwayat.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Belum ada sesi opname yang diselesaikan.',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    return Column(
      children: _riwayat.map((s) {
        final mulai   = DateTime.tryParse(s['tanggal_mulai'].toString());
        final selesai = DateTime.tryParse(s['tanggal_selesai'].toString());
        final tglStr  = selesai != null
            ? DateFormat('dd MMM yyyy, HH:mm').format(selesai) : '-';
        final totalSelisih = int.parse(s['total_selisih'].toString());

        return Container(
          margin    : const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => OpnameDetailPage(opnameId: s['id']),
            )),
            leading: CircleAvatar(
              backgroundColor: totalSelisih > 0
                  ? Colors.red.shade50 : Colors.green.shade50,
              child: Icon(
                totalSelisih > 0 ? Icons.report_gmailerrorred : Icons.verified,
                color: totalSelisih > 0 ? Colors.red : Colors.green,
                size : 20,
              ),
            ),
            title: Text('${s['total_item']} barang dicek',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(
              '${s['nama_admin']} · $tglStr\n'
              '${totalSelisih > 0 ? "$totalSelisih selisih ditemukan" : "Semua sesuai"}',
              style: const TextStyle(fontSize: 11),
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          ),
        );
      }).toList(),
    );
  }
}