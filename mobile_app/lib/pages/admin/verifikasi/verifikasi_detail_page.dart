import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';

class VerifikasiDetailPage extends StatefulWidget {
  final int    permintaanId;
  final String nomorPermintaan;
  const VerifikasiDetailPage({
    super.key,
    required this.permintaanId,
    required this.nomorPermintaan,
  });

  @override
  State<VerifikasiDetailPage> createState() => _VerifikasiDetailPageState();
}

class _VerifikasiDetailPageState extends State<VerifikasiDetailPage> {
  Map<String, dynamic> _data    = {};
  bool                  _loading = true;
  bool                  _mengirim = false;

  String _keputusan = 'Approved';
  final TextEditingController _catatanCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('/admin/verifikasi/${widget.permintaanId}');
    setState(() {
      _data    = res['success'] == true ? Map<String, dynamic>.from(res['data']) : {};
      _loading = false;
    });
    if (res['success'] != true && mounted) {
      _snack(res['message'] ?? 'Gagal memuat data.', isError: true);
    }
  }

  String _fmt(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    return d != null ? DateFormat('dd MMM yyyy, HH:mm').format(d) : '-';
  }

  Future<void> _kirim() async {
    final catatan = _catatanCtrl.text.trim();

    if (_keputusan != 'Approved' && catatan.isEmpty) {
      _snack('Catatan wajib diisi untuk keputusan Rejected / Revision.',
          isError: true);
      return;
    }

    final butuhPimpinan = _data['butuh_pimpinan'] == true;
    final teks = {
      'Approved': butuhPimpinan
          ? 'Teruskan permintaan ini ke Pimpinan untuk disposisi?'
          : 'Setujui permintaan ini? Barang akan langsung siap didistribusikan '
            '(prioritas ini tidak memerlukan persetujuan Pimpinan).',
      'Revision': 'Kembalikan permintaan ini ke User untuk direvisi?',
      'Rejected': 'Tolak permintaan ini dan kembalikan ke User?',
    }[_keputusan]!;

    final yakin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : Text('Konfirmasi $_keputusan'),
        content: Text(teks),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child    : const Text('Ya, Simpan'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    setState(() => _mengirim = true);
    final res = await ApiService.post('/admin/verifikasi/${widget.permintaanId}', {
      'keputusan'       : _keputusan,
      'catatan_approval': catatan,
    });
    setState(() => _mengirim = false);

    if (!mounted) return;

    if (res['success'] == true) {
      _snack(res['message'] ?? 'Keputusan tersimpan.');
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.pop(context, true);
    } else {
      _snack(res['message'] ?? 'Gagal menyimpan keputusan.', isError: true);
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
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      _kartu('Informasi Pemohon', Icons.person_outline, Column(children: [
                        _baris('Nama', p['nama_lengkap']?.toString() ?? '-'),
                        _baris('Bagian', p['bagian']?.toString() ?? '-'),
                        _baris('Jabatan', p['jabatan']?.toString() ?? '-'),
                        _baris('Prioritas', p['prioritas']?.toString() ?? '-'),
                        _baris('Alur', _data['keterangan_alur']?.toString() ?? '-'),
                        _baris('Diajukan', _fmt(p['tanggal_permintaan'])),
                        if ((p['catatan'] ?? '').toString().isNotEmpty)
                          _baris('Catatan', p['catatan'].toString()),
                      ])),

                      const SizedBox(height: 14),

                      _kartu('Daftar Barang (${items.length})',
                          Icons.inventory_2_outlined,
                          Column(children: items.map(_barisBarang).toList())),

                      if (riwayat.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _kartu('Riwayat Keputusan', Icons.history,
                            Column(children: riwayat.map(_barisRiwayat).toList())),
                      ],

                      if (perubahan.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _kartu('Riwayat Perubahan oleh Pemohon', Icons.history,
                            Column(children: perubahan.map(_barisPerubahan).toList())),
                      ],

                      const SizedBox(height: 14),

                      if (status == 'Pending')
                        _formKeputusan()
                      else
                        Container(
                          width  : double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status == 'Cancelled'
                                ? 'Permintaan ini dibatalkan oleh pemohon.'
                                : 'Permintaan ini sudah diverifikasi (status saat ini: $status).',
                            style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 13),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
    );
  }

  // ── Form keputusan ─────────────────────────────────────────
  Widget _formKeputusan() {
    final opsi = <String, List<dynamic>>{
      'Approved': [
        'Approved',
        _data['butuh_pimpinan'] == true
            ? 'Teruskan ke Pimpinan'
            : 'Siap distribusi (tanpa Pimpinan)',
        Colors.green,
      ],
      'Revision': ['Revision', 'Minta revisi User',    Colors.blue],
      'Rejected': ['Rejected', 'Tolak',                Colors.red],
    };

    return _kartu('Keputusan Verifikasi', Icons.rule, Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...opsi.entries.map((e) {
          final pilih  = _keputusan == e.key;
          final warna  = e.value[2] as MaterialColor;
          return GestureDetector(
            onTap: () => setState(() => _keputusan = e.key),
            child: Container(
              margin : const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: pilih ? warna.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: pilih ? warna.shade400 : Colors.grey.shade300,
                    width: pilih ? 1.6 : 1),
              ),
              child: Row(children: [
                Icon(pilih ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: pilih ? warna.shade700 : Colors.grey, size: 20),
                const SizedBox(width: 10),
                Text(e.value[0] as String,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: pilih ? warna.shade800 : Colors.black87)),
                const SizedBox(width: 8),
                Text('— ${e.value[1]}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ]),
            ),
          );
        }),
        const SizedBox(height: 6),
        TextField(
          controller: _catatanCtrl,
          maxLines  : 3,
          maxLength : 500,
          decoration: InputDecoration(
            labelText: _keputusan == 'Approved'
                ? 'Catatan (opsional)'
                : 'Catatan (wajib — dibaca User)',
            hintText : _keputusan == 'Approved'
                ? 'Catatan untuk Pimpinan / User...'
                : 'Jelaskan alasan atau hal yang perlu diperbaiki...',
            border   : OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _mengirim ? null : _kirim,
          icon     : _mengirim
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded),
          label: Text(_mengirim ? 'Menyimpan...' : 'Simpan Keputusan'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    ));
  }

  // ── Baris barang + peringatan stok ─────────────────────────
  Widget _barisBarang(dynamic it) {
    final jumlah = int.tryParse(it['jumlah'].toString()) ?? 0;
    final stok   = int.tryParse(it['stok_tersedia'].toString()) ?? 0;
    final kurang = jumlah > stok;

    return Container(
      margin : const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kurang ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kurang ? Colors.red.shade200 : Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(it['nama_barang']?.toString() ?? '-',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Text('$jumlah ${it['satuan'] ?? ''}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.primaryColor))),
        ]),
        const SizedBox(height: 3),
        Text('${it['kode_barang'] ?? ''} · ${it['nama_kategori'] ?? ''}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 3),
        Text(
          kurang
              ? 'Stok tersedia $stok ${it['satuan'] ?? ''} — TIDAK MENCUKUPI'
              : 'Stok tersedia $stok ${it['satuan'] ?? ''}',
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w600,
              color: kurang ? Colors.red.shade700 : Colors.green.shade700),
        ),
        if ((it['keterangan'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 3),
          Text('Ket: ${it['keterangan']}',
              style: TextStyle(
                  fontSize: 11.5, fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600)),
        ],
      ]),
    );
  }

  Widget _barisPerubahan(dynamic l) {
    final ringkasan = (l['ringkasan'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${l['jenis']} · ${_fmt(l['created_at'])}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text('oleh ${l['nama_pelaku'] ?? '-'}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        if (ringkasan.isNotEmpty)
          Text(ringkasan, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  Widget _barisRiwayat(dynamic a) {
    final catat = (a['catatan_approval'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${a['keputusan']} · Tahap ${a['tahap'] ?? '-'}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text('oleh ${a['nama_pengambil_keputusan'] ?? '-'} · ${_fmt(a['tanggal_approval'])}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        if (catat.isNotEmpty)
          Text('Catatan: $catat', style: const TextStyle(fontSize: 12)),
      ]),
    );
  }

  Widget _kartu(String judul, IconData icon, Widget child) => Container(
    width  : double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: const Color(AppConstants.primaryColor), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(judul,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ]),
      const Divider(height: 20),
      child,
    ]),
  );

  Widget _baris(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child  : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 90,
        child: Text(label, style: const TextStyle(fontSize: 12.5, color: Colors.grey)),
      ),
      Expanded(
        child: Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}
