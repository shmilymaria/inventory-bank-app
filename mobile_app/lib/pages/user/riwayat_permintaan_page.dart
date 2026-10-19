import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/utils/status_permintaan.dart';
import 'package:inventori_bank/pages/user/detail_permintaan_page.dart';

class RiwayatPermintaanPage extends StatefulWidget {
  const RiwayatPermintaanPage({super.key});
  @override
  State<RiwayatPermintaanPage> createState() => RiwayatPermintaanPageState();
}

// State dibuat public agar bisa dipanggil dari UserMainPage / Beranda
class RiwayatPermintaanPageState extends State<RiwayatPermintaanPage> {
  List<dynamic> _data    = [];
  String        _filter  = ''; // '' = Semua
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    muat();
  }

  /// Muat ulang daftar (dipakai juga saat tab dibuka kembali).
  Future<void> muat() async {
    final ep = _filter.isEmpty
        ? '/permintaan'
        : '/permintaan?status=$_filter';
    final res = await ApiService.get(ep);
    if (!mounted) return;
    setState(() {
      _data    = res['data'] ?? [];
      _loading = false;
    });
  }

  /// Dari Beranda: tampilkan riwayat dengan status tertentu ('' = Semua).
  void setFilter(String status) {
    setState(() {
      _filter  = status;
      _loading = true;
    });
    muat();
  }

  // Dipanggil dari UserMainPage saat tap permintaan di dashboard / setelah kirim
  void bukaDetail(int permintaanId, String nomorPermintaan) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPermintaanPage(
          permintaanId   : permintaanId,
          nomorPermintaan: nomorPermintaan,
        ),
      ),
    ).then((_) => muat());
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : const Text('Riwayat Permintaan'),
        backgroundColor: primary,
        automaticallyImplyLeading: false,
      ),
      body: Column(children: [

        // ── Tombol filter status ─────────────────────────
        Container(
          color  : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 0, 10),
          child  : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['', ...StatusPermintaan.semua].map((s) {
                final aktif = _filter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child  : ChoiceChip(
                    label   : Text(s.isEmpty ? 'Semua' : s),
                    selected: aktif,
                    onSelected: (_) => setFilter(s),
                    selectedColor: const Color(AppConstants.primaryLightColor),
                    labelStyle: TextStyle(
                      color     : aktif ? primary : Colors.grey.shade700,
                      fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
                      fontSize  : 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: muat,
                  child: _data.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 120),
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                _filter.isEmpty
                                    ? 'Belum ada riwayat permintaan.'
                                    : 'Tidak ada permintaan berstatus $_filter.',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _data.length,
                          itemBuilder: (_, i) => _kartu(_data[i]),
                        ),
                ),
        ),
      ]),
    );
  }

  Widget _kartu(dynamic p) {
    final status    = p['status_permintaan']?.toString() ?? '';
    final prioritas = p['prioritas']?.toString() ?? '';
    final warna     = Color(StatusPermintaan.warna(status));
    final tanggal   = DateTime.tryParse(p['tanggal_permintaan']?.toString() ?? '');
    final tglStr    = tanggal != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(tanggal) : '-';
    final totalItem = p['total_item']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(children: [
            Expanded(
              child: Text(p['nomor_permintaan']?.toString() ?? '-',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14.5)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Color(StatusPermintaan.latar(status)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(StatusPermintaan.ikon(status), size: 13, color: warna),
                const SizedBox(width: 4),
                Text(status,
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.bold,
                        color: warna)),
              ]),
            ),
          ]),

          const SizedBox(height: 4),
          Text(tglStr,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(StatusPermintaan.keterangan(status, prioritas: prioritas),
              style: TextStyle(fontSize: 12, color: warna)),

          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.flag_outlined, size: 15, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(prioritas,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            if (totalItem != null) ...[
              const SizedBox(width: 12),
              Icon(Icons.inventory_2_outlined,
                  size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('$totalItem barang',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
            const Spacer(),
            OutlinedButton(
              onPressed: () => bukaDetail(
                int.parse(p['id'].toString()),
                p['nomor_permintaan']?.toString() ?? '',
              ),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Lihat Detail', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ]),
      ),
    );
  }
}
