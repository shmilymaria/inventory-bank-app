import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/pages/admin/inbound/inbound_tally_scan_page.dart';
import 'package:inventori_bank/pages/admin/inbound/tambah_barang_baru_page.dart';

class ScanInboundPage extends StatefulWidget {
  const ScanInboundPage({super.key});
  @override
  State<ScanInboundPage> createState() => _ScanInboundPageState();
}

class _ScanInboundPageState extends State<ScanInboundPage> {
  List<dynamic> _barang         = [];
  List<dynamic> _filteredBarang = [];
  List<dynamic> _riwayat        = [];
  bool          _loading        = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.get('/barang'), // katalog — endpoint sama seperti Ajukan Permintaan User
      ApiService.get('/admin/inbound/riwayat'),
    ]);

    final rawBarang = (results[0]['success'] == true) ? (results[0]['data'] ?? []) : [];
    setState(() {
      _barang         = rawBarang;
      _filteredBarang = rawBarang;
      _riwayat        = (results[1]['success'] == true) ? (results[1]['data'] ?? []) : [];
      _loading        = false;
    });
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredBarang = q.isEmpty
          ? _barang
          : _barang.where((b) {
              final nama = (b['nama_barang'] ?? '').toString().toLowerCase();
              final kode = (b['kode_barang'] ?? '').toString().toLowerCase();
              final kat  = (b['nama_kategori'] ?? '').toString().toLowerCase();
              return nama.contains(q) || kode.contains(q) || kat.contains(q);
            }).toList();
    });
  }

  Future<void> _bukaTambahBarangBaru({String? kodeAwal}) async {
    final barangBaru = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => TambahBarangBaruPage(kodeAwal: kodeAwal),
    ));
    if (barangBaru != null && mounted) {
      // Langsung lanjut ke layar scan tally untuk barang yang baru dibuat
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => InboundTallyScanPage(barang: barangBaru),
      ));
      _load();
    }
  }

  Future<void> _bukaTallyScan(dynamic barang) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => InboundTallyScanPage(barang: barang),
    ));
    _load();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaTambahBarangBaru(),
        icon     : const Icon(Icons.add),
        label    : const Text('Barang Baru'),
        backgroundColor: primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: Column(children: [

                Container(
                  width  : double.infinity,
                  padding: const EdgeInsets.all(16),
                  color  : Colors.white,
                  child  : TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText  : 'Cari nama barang, kode, atau kategori...',
                      prefixIcon: const Icon(Icons.search),
                      filled    : true,
                      fillColor : const Color(AppConstants.bgColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide  : BorderSide.none,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    child  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        _filteredBarang.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Center(child: Column(children: [
                                  Icon(Icons.inventory_2_outlined,
                                      size: 50, color: Colors.grey.shade400),
                                  const SizedBox(height: 10),
                                  Text(
                                    _searchCtrl.text.isEmpty
                                        ? 'Belum ada barang terdaftar.'
                                        : 'Barang "${_searchCtrl.text}" tidak ditemukan.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ])),
                              )
                            : GridView.builder(
                                shrinkWrap: true,
                                physics   : const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount  : 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing : 12,
                                ),
                                itemCount: _filteredBarang.length,
                                itemBuilder: (context, i) =>
                                    _catalogCard(_filteredBarang[i]),
                              ),

                        const SizedBox(height: 24),
                        const Text('Riwayat Inbound Terbaru',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 10),
                        _riwayatList(),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _catalogCard(dynamic barang) {
    final stok   = int.tryParse(barang['stok'].toString()) ?? 0;
    final gambar = AppConstants.resolveImageUrl(barang['gambar']?.toString());
    final habis  = stok <= 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _bukaTallyScan(barang),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: gambar.isNotEmpty
                  ? Image.network(gambar, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImg())
                  : _placeholderImg(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(barang['nama_barang']?.toString() ?? '',
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Stok: $stok ${barang['satuan'] ?? ''}',
                  style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600,
                      color: habis ? Colors.red.shade400 : Colors.green.shade700),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _placeholderImg() => Container(
    color: const Color(AppConstants.primaryLightColor),
    alignment: Alignment.center,
    child: const Icon(Icons.inventory_2_outlined,
        size: 32, color: Color(AppConstants.primaryColor)),
  );

  Widget _riwayatList() {
    if (_riwayat.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
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
            ? DateFormat('dd MMM yyyy, HH:mm').format(tanggal) : '-';

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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r['nama_barang']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text('+${r['jumlah']} ${r['satuan'] ?? ''} · $tglStr',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ]),
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