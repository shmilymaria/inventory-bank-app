import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/utils/status_permintaan.dart';
import 'package:inventori_bank/pages/user/edit_permintaan_page.dart';

/// Detail permintaan (dipakai dari Riwayat, notifikasi, dan setelah kirim):
/// Status Permintaan → (aksi) → QR → Informasi → Barang → Riwayat Keputusan
/// → Riwayat Perubahan.
class DetailPermintaanPage extends StatefulWidget {
  final int    permintaanId;
  final String nomorPermintaan;

  const DetailPermintaanPage({
    super.key,
    required this.permintaanId,
    required this.nomorPermintaan,
  });

  @override
  State<DetailPermintaanPage> createState() => _DetailPermintaanPageState();
}

class _DetailPermintaanPageState extends State<DetailPermintaanPage> {
  Map<String, dynamic> _data    = {};
  bool                  _loading = true;
  bool                  _memproses = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.get('/permintaan/${widget.permintaanId}');
    if (!mounted) return;
    setState(() {
      _data    = res['success'] == true
          ? Map<String, dynamic>.from(res['data'])
          : {};
      _loading = false;
    });
    if (res['success'] != true) {
      _snack(res['message'] ?? 'Gagal memuat detail permintaan.', isError: true);
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

  // ── Aksi ──────────────────────────────────────────────────
  /// Keputusan Revision terakhir (untuk ditampilkan di halaman revisi)
  Map<String, dynamic>? get _keputusanRevisi {
    final riwayat = (_data['riwayat_approval'] as List?) ?? [];
    for (final a in riwayat) {
      if (a['keputusan'] == 'Revision') return Map<String, dynamic>.from(a);
    }
    return null;
  }

  Future<void> _bukaEdit({required bool revisi}) async {
    final rev = revisi ? _keputusanRevisi : null;

    final pesan = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPermintaanPage(
          mode            : revisi ? 'revisi' : 'edit',
          permintaan      : Map<String, dynamic>.from(_data['permintaan']),
          items           : (_data['detail_items'] as List?) ?? [],
          catatanKeputusan: rev?['catatan_approval']?.toString(),
          tahapKeputusan  : rev?['tahap']?.toString(),
        ),
      ),
    );

    if (pesan != null && mounted) {
      _snack(pesan);
      await _load();
    }
  }

  Future<void> _batalkan() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Batalkan Permintaan'),
        content: const Text('Apakah Anda yakin ingin membatalkan permintaan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style    : ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child    : const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    setState(() => _memproses = true);
    final res = await ApiService.post(
        '/permintaan/${widget.permintaanId}/batal', {});
    if (!mounted) return;
    setState(() => _memproses = false);

    if (res['success'] == true) {
      _snack(res['message'] ?? 'Permintaan dibatalkan.');
      await _load();
    } else {
      _snack(res['message'] ?? 'Gagal membatalkan permintaan.', isError: true);
      await _load(); // status mungkin sudah berubah (diproses Admin)
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    final p        = _data['permintaan'];
    final items    = (_data['detail_items'] as List?) ?? [];
    final riwayat  = (_data['riwayat_approval'] as List?) ?? [];
    final perubahan = (_data['riwayat_perubahan'] as List?) ?? [];
    final status   = p?['status_permintaan']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : Text(widget.nomorPermintaan),
        backgroundColor: primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : p == null
              ? const Center(child: Text('Data tidak ditemukan.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [

                      _bannerStatus(status, p['prioritas']?.toString()),
                      const SizedBox(height: 14),

                      ..._aksi(status),

                      if (_data['siap_diambil'] == true &&
                          (p['qr_token'] ?? '').toString().isNotEmpty) ...[
                        _qrCard(p['qr_token'].toString()),
                        const SizedBox(height: 14),
                      ],

                      _infoCard(p),
                      const SizedBox(height: 14),

                      _itemsCard(items),
                      const SizedBox(height: 14),

                      _keputusanCard(riwayat, status),
                      const SizedBox(height: 14),

                      _perubahanCard(perubahan),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  // ── 1. Status Permintaan ──────────────────────────────────
  Widget _bannerStatus(String status, String? prioritas) {
    final warna = Color(StatusPermintaan.warna(status));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(StatusPermintaan.latar(status)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle),
          child: Icon(StatusPermintaan.ikon(status), color: warna, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Status Permintaan',
                style: TextStyle(fontSize: 11.5, color: Colors.black54)),
            const SizedBox(height: 2),
            Text(status,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: warna)),
            const SizedBox(height: 2),
            Text(StatusPermintaan.keterangan(status, prioritas: prioritas),
                style: TextStyle(fontSize: 12.5, color: warna)),
          ]),
        ),
      ]),
    );
  }

  // ── 2. Tombol aksi (sesuai status) ────────────────────────
  List<Widget> _aksi(String status) {
    // Revision → User merevisi di permintaan yang sama
    if (_data['bisa_revisi'] == true) {
      final rev   = _keputusanRevisi;
      final tahap = rev?['tahap']?.toString() ?? 'Admin';
      final catat = (rev?['catatan_approval'] ?? '').toString();

      return [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.refresh, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text('Permintaan perlu direvisi ($tahap)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
            ]),
            if (catat.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Catatan: $catat', style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Text(
              'Anda bisa merevisi langsung di permintaan ini (nomor tetap). '
              'Ubah jumlah, prioritas & catatan, atau hapus barang yang '
              'tidak disetujui. Barang baru tidak dapat ditambahkan.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _memproses ? null : () => _bukaEdit(revisi: true),
              icon : const Icon(Icons.edit_note),
              label: const Text('Revisi Permintaan'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
      ];
    }

    // Pending → Edit & Batalkan
    if (_data['bisa_edit'] == true) {
      return [
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _memproses ? null : () => _bukaEdit(revisi: false),
              icon : const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Permintaan'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _memproses ? null : _batalkan,
              icon : const Icon(Icons.block, size: 18),
              label: const Text('Batalkan Permintaan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade300),
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          'Edit & pembatalan hanya bisa dilakukan selama status masih Pending.',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
      ];
    }

    // Sudah diproses → tombol terkunci (info saja)
    if (['Verified', 'Approved', 'Distributed'].contains(status)) {
      return [
        Row(children: [
          Icon(Icons.lock_outline, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Permintaan sudah diproses, sehingga tidak bisa diedit atau '
              'dibatalkan (demi akurasi stok dan data administrasi).',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ),
        ]),
        const SizedBox(height: 14),
      ];
    }

    return [];
  }

  // ── 3. QR Serah Terima ────────────────────────────────────
  Widget _qrCard(String token) => Container(
    width  : double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: const Color(AppConstants.primaryColor).withOpacity(0.3)),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Column(children: [
      const Row(children: [
        Icon(Icons.qr_code_2,
            color: Color(AppConstants.primaryColor), size: 20),
        SizedBox(width: 8),
        Text('QR Serah Terima Barang',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ]),
      const Divider(height: 20),
      QrImageView(
        data           : token,
        version        : QrVersions.auto,
        size           : 190,
        backgroundColor: Colors.white,
      ),
      const SizedBox(height: 14),
      Text(
        'Tunjukkan QR ini ke Admin saat mengambil barang. '
        'Admin akan scan QR ini sebagai bukti barang sudah diserahkan.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
    ]),
  );

  // ── 4. Informasi Permintaan ───────────────────────────────
  Widget _infoCard(dynamic p) {
    final prioritas = p['prioritas']?.toString() ?? '';
    final info      = InfoPrioritas.cari(prioritas);
    final warna     = info.warna as MaterialColor;
    final catatan   = (p['catatan'] ?? '').toString();

    return _card(
      title: 'Informasi Permintaan',
      icon : Icons.info_outline,
      child: Column(children: [
        _baris('Nomor', p['nomor_permintaan']?.toString() ?? '-'),
        _pemisah(),
        _baris('Tanggal', _fmt(p['tanggal_permintaan'])),
        _pemisah(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(
              width: 100,
              child: Text('Prioritas',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey)),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: warna.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: warna.shade300),
                  ),
                  child: Text(prioritas,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold,
                          color: warna.shade900)),
                ),
                const SizedBox(height: 4),
                Text(info.alur,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              ]),
            ),
          ]),
        ),
        _pemisah(),
        _baris('Catatan', catatan.isEmpty ? '-' : catatan),
      ]),
    );
  }

  // ── 5. Barang yang Diminta ────────────────────────────────
  Widget _itemsCard(List items) {
    return _card(
      title: 'Barang yang Diminta (${items.length})',
      icon : Icons.inventory_2_outlined,
      child: Column(
        children: items.map((it) {
          final gambar = AppConstants.resolveImageUrl(it['gambar']?.toString());
          final ket    = (it['keterangan'] ?? '').toString();

          return Container(
            margin : const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(AppConstants.bgColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48, height: 48,
                  child: gambar.isNotEmpty
                      ? Image.network(gambar, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it['nama_barang']?.toString() ?? '-',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('${it['kode_barang'] ?? ''} · ${it['nama_kategori'] ?? ''}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  if (ket.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('Ket: $ket',
                        style: TextStyle(
                            fontSize: 11.5, fontStyle: FontStyle.italic,
                            color: Colors.grey.shade600)),
                  ],
                ]),
              ),
              Text('${it['jumlah']} ${it['satuan'] ?? ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(AppConstants.primaryColor))),
            ]),
          );
        }).toList(),
      ),
    );
  }

  // ── 6. Riwayat Keputusan (Admin & Pimpinan) ───────────────
  Widget _keputusanCard(List riwayat, String status) {
    return _card(
      title: 'Riwayat Keputusan',
      icon : Icons.verified_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        if (riwayat.isEmpty)
          Row(children: [
            const Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                status == 'Pending'
                    ? 'Menunggu verifikasi Admin.'
                    : (status == 'Cancelled'
                        ? 'Permintaan dibatalkan sebelum diverifikasi.'
                        : 'Belum ada keputusan.'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ]),

        ...List.generate(riwayat.length, (i) {
          final a     = riwayat[i];
          final k     = (a['keputusan'] ?? '').toString();
          final tahap = (a['tahap'] ?? 'Pimpinan').toString();
          final catat = (a['catatan_approval'] ?? '').toString();

          return Container(
            margin : EdgeInsets.only(bottom: i == riwayat.length - 1 ? 0 : 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _keputusanBg(k),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_keputusanIkon(k), color: _keputusanWarna(k), size: 20),
                const SizedBox(width: 8),
                Text(k, style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14,
                    color: _keputusanWarna(k))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Tahap $tahap',
                      style: const TextStyle(fontSize: 10.5, color: Colors.black87)),
                ),
              ]),
              const SizedBox(height: 6),
              Text('oleh ${a['nama_pimpinan'] ?? '-'} · ${_fmt(a['tanggal_approval'])}',
                  style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
              if (catat.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Catatan: $catat', style: const TextStyle(fontSize: 12.5)),
              ],
            ]),
          );
        }),

        if (status == 'Verified' && _data['butuh_pimpinan'] == true) ...[
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.hourglass_empty, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Menunggu keputusan Pimpinan.',
                  style: TextStyle(color: Colors.grey, fontSize: 12.5)),
            ),
          ]),
        ],
      ]),
    );
  }

  // ── 7. Riwayat Perubahan (Edit / Revisi / Batal) ──────────
  Widget _perubahanCard(List perubahan) {
    return _card(
      title: 'Riwayat Perubahan',
      icon : Icons.history,
      child: perubahan.isEmpty
          ? Text('Belum ada perubahan pada permintaan ini.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600))
          : Column(
              children: List.generate(perubahan.length, (i) {
                final l     = perubahan[i];
                final jenis = (l['jenis'] ?? '').toString();
                final ikon  = jenis == 'Revisi'
                    ? Icons.refresh
                    : (jenis == 'Batal' ? Icons.block : Icons.edit_outlined);
                final warna = jenis == 'Revisi'
                    ? Colors.blue
                    : (jenis == 'Batal' ? Colors.grey : Colors.orange);

                return Padding(
                  padding: EdgeInsets.only(
                      bottom: i == perubahan.length - 1 ? 0 : 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: warna.shade50, shape: BoxShape.circle),
                      child: Icon(ikon, size: 16, color: warna.shade700),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          jenis == 'Revisi'
                              ? 'Revisi dikirim ulang'
                              : (jenis == 'Batal'
                                  ? 'Permintaan dibatalkan'
                                  : 'Permintaan diedit'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${_fmt(l['created_at'])} · ${l['nama_pelaku'] ?? '-'}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                        if ((l['ringkasan'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(l['ringkasan'].toString(),
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ]),
                    ),
                  ]),
                );
              }),
            ),
    );
  }

  // ── Helper tampilan ───────────────────────────────────────
  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) => Container(
    width  : double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: const Color(AppConstants.primaryColor), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ]),
      const Divider(height: 20),
      child,
    ]),
  );

  Widget _baris(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child  : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 100,
        child: Text(label,
            style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
      ),
      Expanded(
        child: Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ]),
  );

  Widget _pemisah() => Divider(height: 1, color: Colors.grey.shade200);

  Widget _placeholder() => Container(
    color: const Color(AppConstants.primaryLightColor),
    alignment: Alignment.center,
    child: const Icon(Icons.inventory_2_outlined,
        size: 22, color: Color(AppConstants.primaryColor)),
  );

  String _fmt(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    return d != null ? DateFormat('dd MMM yyyy, HH:mm').format(d) : '-';
  }

  Color _keputusanBg(String k) => k == 'Approved'
      ? Colors.green.shade50
      : (k == 'Rejected' ? Colors.red.shade50 : Colors.blue.shade50);

  Color _keputusanWarna(String k) => k == 'Approved'
      ? Colors.green.shade800
      : (k == 'Rejected' ? Colors.red.shade800 : Colors.blue.shade800);

  IconData _keputusanIkon(String k) => k == 'Approved'
      ? Icons.check_circle
      : (k == 'Rejected' ? Icons.cancel : Icons.refresh);
}
