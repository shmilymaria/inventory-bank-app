import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/services/auth_service.dart';
import 'package:inventori_bank/utils/status_permintaan.dart';
import 'package:inventori_bank/pages/user/user_main_page.dart';

/// Beranda User:
///  1. Header: avatar inisial, sapaan, bagian/unit kerja, tombol notifikasi
///  2. Ringkasan Permintaan (tiap kartu bisa ditekan → Riwayat sesuai status)
///  3. Kategori Barang (→ tab Ajukan dengan kelompok yang dipilih)
///  4. Permintaan Terbaru (5 terakhir)
class UserDashboardPage extends StatefulWidget {
  // Referensi ke parent agar bisa navigasi antar tab
  final UserMainPageState? mainPageState;

  const UserDashboardPage({super.key, this.mainPageState});

  @override
  State<UserDashboardPage> createState() => UserDashboardPageState();
}

class UserDashboardPageState extends State<UserDashboardPage> {
  Map<String, dynamic> _dash = {};
  Map<String, dynamic> _user = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    muat();
  }

  /// Muat ulang (dipanggil juga saat tab Beranda dibuka kembali).
  Future<void> muat() async {
    final results = await Future.wait([
      ApiService.get('/dashboard'),
      AuthService.getUserData(),
    ]);
    if (!mounted) return;
    setState(() {
      _dash    = Map<String, dynamic>.from(results[0]['data'] ?? {});
      _user    = results[1];
      _loading = false;
    });
  }

  int _n(String key) => int.tryParse((_dash[key] ?? 0).toString()) ?? 0;

  String get _inisial {
    final nama = (_user['nama_lengkap'] ?? '').toString().trim();
    if (nama.isEmpty) return '?';
    final kata = nama.split(RegExp(r'\s+'));
    return kata.length == 1
        ? kata[0][0].toUpperCase()
        : (kata[0][0] + kata[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: muat,
              color    : primary,
              child    : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child  : Column(children: [
                  _header(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_n('revision') > 0) ...[
                          _bannerRevisi(),
                          const SizedBox(height: 16),
                        ],
                        _ringkasan(),
                        const SizedBox(height: 22),
                        _kategori(),
                        const SizedBox(height: 22),
                        _terbaru(),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
    );
  }

  // ── 1. Header ─────────────────────────────────────────────
  Widget _header() {
    final nama   = (_user['nama_lengkap'] ?? '').toString();
    final bagian = (_user['bagian'] ?? '').toString();
    final belumDibaca = _n('notifikasi_belum_dibaca');

    return Container(
      width  : double.infinity,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 14, 16, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(AppConstants.primaryColor),
            Color(AppConstants.primaryDarkColor),
          ],
          begin: Alignment.topLeft,
          end  : Alignment.bottomRight,
        ),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white24,
          child: Text(_inisial,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Selamat datang,',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(nama.isEmpty ? 'Pengguna' : nama,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 17,
                    fontWeight: FontWeight.bold)),
            if (bagian.isNotEmpty)
              Text(bagian,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        // Tombol notifikasi → tab Notifikasi
        InkWell(
          onTap: () => widget.mainPageState?.goToTab(3),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Badge(
              isLabelVisible: belumDibaca > 0,
              label: Text(belumDibaca > 99 ? '99+' : '$belumDibaca'),
              child: const Icon(Icons.notifications_outlined,
                  color: Colors.white, size: 26),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Pengingat revisi ──────────────────────────────────────
  Widget _bannerRevisi() => InkWell(
    onTap: () => widget.mainPageState?.goToRiwayat('Revision'),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(children: [
        Icon(Icons.refresh, color: Colors.blue.shade700, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text('${_n('revision')} permintaan perlu Anda revisi',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900)),
        ),
        Text('Lihat',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: Colors.blue.shade700)),
        Icon(Icons.chevron_right, color: Colors.blue.shade700),
      ]),
    ),
  );

  // ── 2. Ringkasan Permintaan ───────────────────────────────
  Widget _ringkasan() {
    final kartu = <Map<String, dynamic>>[
      {'label': 'Total',       'nilai': _n('total_permintaan'), 'status': '',            'warna': const Color(AppConstants.primaryColor), 'ikon': Icons.list_alt},
      {'label': 'Pending',     'nilai': _n('pending'),          'status': 'Pending',     'warna': Color(StatusPermintaan.warna('Pending')),     'ikon': StatusPermintaan.ikon('Pending')},
      {'label': 'Verified',    'nilai': _n('verified'),         'status': 'Verified',    'warna': Color(StatusPermintaan.warna('Verified')),    'ikon': StatusPermintaan.ikon('Verified')},
      {'label': 'Approved',    'nilai': _n('approved'),         'status': 'Approved',    'warna': Color(StatusPermintaan.warna('Approved')),    'ikon': StatusPermintaan.ikon('Approved')},
      {'label': 'Distributed', 'nilai': _n('distributed'),      'status': 'Distributed', 'warna': Color(StatusPermintaan.warna('Distributed')), 'ikon': StatusPermintaan.ikon('Distributed')},
    ];

    Widget tile(Map<String, dynamic> k) => InkWell(
      onTap: () => widget.mainPageState?.goToRiwayat(k['status'] as String),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(children: [
          Icon(k['ikon'] as IconData, color: k['warna'] as Color, size: 22),
          const SizedBox(height: 6),
          Text('${k['nilai']}',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: k['warna'] as Color)),
          Text(k['label'] as String,
              style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        ]),
      ),
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ringkasan Permintaan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount  : 3,
        shrinkWrap      : true,
        physics         : const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing : 10,
        childAspectRatio: 1.05,
        children: kartu.map(tile).toList(),
      ),
    ]);
  }

  // ── 3. Kategori Barang ────────────────────────────────────
  Widget _kategori() {
    final daftar = <Map<String, dynamic>>[
      {'label': 'Alat Tulis Kantor', 'kelompok': 'ATK',            'ikon': Icons.edit_outlined,        'warna': Colors.indigo},
      {'label': 'Barang Cetakan',    'kelompok': 'Barang Cetakan', 'ikon': Icons.print_outlined,       'warna': Colors.teal},
      {'label': 'Barang Lainnya',    'kelompok': 'Barang Lainnya', 'ikon': Icons.category_outlined,    'warna': Colors.orange},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Kategori Barang',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 10),
      Row(
        children: daftar.map((k) {
          final warna = k['warna'] as MaterialColor;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: k == daftar.last ? 0 : 10),
              child: InkWell(
                onTap: () => widget.mainPageState
                    ?.goToAjukan(kelompok: k['kelompok'] as String),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                  decoration: BoxDecoration(
                    color: warna.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: warna.shade100),
                  ),
                  child: Column(children: [
                    Icon(k['ikon'] as IconData, color: warna.shade700, size: 26),
                    const SizedBox(height: 6),
                    Text(k['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w600,
                            color: warna.shade900)),
                  ]),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  // ── 4. Permintaan Terbaru ─────────────────────────────────
  Widget _terbaru() {
    final list = (_dash['permintaan_terbaru'] as List?) ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(
          child: Text('Permintaan Terbaru',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        TextButton(
          onPressed: () => widget.mainPageState?.goToRiwayat(''),
          child    : const Text('Lihat Semua'),
        ),
      ]),
      const SizedBox(height: 4),

      if (list.isEmpty)
        Container(
          width  : double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: [
            Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            const Text('Belum ada permintaan.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text('Ketuk tombol + di bawah untuk mengajukan.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ]),
        )
      else
        ...list.map((p) {
          final status  = p['status_permintaan']?.toString() ?? '';
          final warna   = Color(StatusPermintaan.warna(status));
          final tanggal = DateTime.tryParse(p['tanggal_permintaan']?.toString() ?? '');
          final tglStr  = tanggal != null
              ? DateFormat('dd MMM yyyy').format(tanggal) : '-';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => widget.mainPageState?.goToRiwayatDetail(
                int.parse(p['id'].toString()),
                p['nomor_permintaan']?.toString() ?? '',
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child  : Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Color(StatusPermintaan.latar(status)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(StatusPermintaan.ikon(status),
                        size: 20, color: warna),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['nomor_permintaan']?.toString() ?? '-',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text('$tglStr · ${p['prioritas'] ?? ''}'
                          '${p['total_item'] != null ? ' · ${p['total_item']} barang' : ''}',
                          style: TextStyle(
                              fontSize: 11.5, color: Colors.grey.shade600)),
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(status,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: warna)),
                    const SizedBox(height: 2),
                    const Text('Lihat Detail',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(AppConstants.primaryColor))),
                  ]),
                ]),
              ),
            ),
          );
        }),
    ]);
  }
}
