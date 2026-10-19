import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/utils/status_permintaan.dart';
import 'package:inventori_bank/widgets/prioritas_selector.dart';
import 'package:inventori_bank/widgets/qty_stepper.dart';

/// Satu baris barang yang sedang diedit.
class _Baris {
  final int    detailId;
  final String nama;
  final String kategori;
  final String satuan;
  final String gambar;
  final int    stok;
  final int    jumlahAwal;
  int          jumlah;

  _Baris({
    required this.detailId,
    required this.nama,
    required this.kategori,
    required this.satuan,
    required this.gambar,
    required this.stok,
    required this.jumlahAwal,
  }) : jumlah = jumlahAwal;
}

/// Edit permintaan (status Pending) ATAU revisi (status Revision).
///
/// Aturan yang sama untuk keduanya — hanya boleh:
///   • mengubah jumlah barang
///   • mengubah prioritas & catatan
///   • menghapus barang
/// TIDAK bisa menambah barang baru ke permintaan yang sama.
/// Revisi memakai permintaan & nomor yang sama (bukan permintaan baru).
class EditPermintaanPage extends StatefulWidget {
  /// 'edit' | 'revisi'
  final String mode;
  final Map<String, dynamic> permintaan;
  final List<dynamic> items;

  /// Catatan & asal keputusan Revision terakhir (untuk mode revisi)
  final String? catatanKeputusan;
  final String? tahapKeputusan;

  const EditPermintaanPage({
    super.key,
    required this.mode,
    required this.permintaan,
    required this.items,
    this.catatanKeputusan,
    this.tahapKeputusan,
  });

  @override
  State<EditPermintaanPage> createState() => _EditPermintaanPageState();
}

class _EditPermintaanPageState extends State<EditPermintaanPage> {
  late final List<_Baris> _baris;
  late final int          _jumlahItemAwal;
  late String             _prioritas;
  late final String       _prioritasAwal;
  late final String       _catatanAwal;
  final TextEditingController _catatanCtrl = TextEditingController();
  bool _menyimpan = false;

  bool get _revisi => widget.mode == 'revisi';

  @override
  void initState() {
    super.initState();
    _baris = widget.items.map((it) => _Baris(
      detailId  : int.parse(it['id'].toString()),
      nama      : it['nama_barang']?.toString()   ?? '',
      kategori  : it['nama_kategori']?.toString() ?? '',
      satuan    : it['satuan']?.toString()        ?? '',
      gambar    : AppConstants.resolveImageUrl(it['gambar']?.toString()),
      stok      : int.tryParse(it['stok'].toString())   ?? 0,
      jumlahAwal: int.tryParse(it['jumlah'].toString()) ?? 1,
    )).toList();

    _jumlahItemAwal = _baris.length;
    _prioritas      = widget.permintaan['prioritas']?.toString() ?? 'Normal';
    _prioritasAwal  = _prioritas;
    _catatanAwal    = (widget.permintaan['catatan'] ?? '').toString().trim();
    _catatanCtrl.text = _catatanAwal;
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  // Ada perubahan dibanding data awal?
  bool get _adaPerubahan {
    if (_baris.length != _jumlahItemAwal) return true;
    if (_baris.any((b) => b.jumlah != b.jumlahAwal)) return true;
    if (_prioritas != _prioritasAwal) return true;
    return _catatanCtrl.text.trim() != _catatanAwal;
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

  Future<void> _hapus(_Baris b) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Hapus barang?'),
        content: Text('"${b.nama}" akan dikeluarkan dari permintaan ini.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child    : const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style    : ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child    : const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin == true) setState(() => _baris.remove(b));
  }

  Future<void> _simpan() async {
    final catatan = _catatanCtrl.text.trim();

    if (_baris.isEmpty) {
      _snack('Minimal harus ada 1 barang dalam permintaan.', isError: true);
      return;
    }
    if (InfoPrioritas.wajibCatatan(_prioritas) && catatan.isEmpty) {
      _snack('Catatan wajib diisi untuk prioritas $_prioritas.', isError: true);
      return;
    }
    if (!_adaPerubahan) {
      _snack('Belum ada perubahan.', isError: true);
      return;
    }
    for (final b in _baris) {
      if (b.jumlah > b.stok) {
        _snack('Stok "${b.nama}" kini hanya ${b.stok} ${b.satuan}. '
            'Kurangi jumlahnya.', isError: true);
        return;
      }
    }

    setState(() => _menyimpan = true);
    final id   = widget.permintaan['id'];
    final body = {
      'prioritas': _prioritas,
      'catatan'  : catatan,
      'items'    : _baris.map((b) => {
        'detail_id': b.detailId,
        'jumlah'   : b.jumlah,
      }).toList(),
    };

    final res = _revisi
        ? await ApiService.put('/permintaan/$id/revisi', body)
        : await ApiService.put('/permintaan/$id', body);
    if (!mounted) return;
    setState(() => _menyimpan = false);

    if (res['success'] == true) {
      Navigator.pop(context, res['message']?.toString() ?? 'Tersimpan.');
    } else {
      _snack(res['message'] ?? 'Gagal menyimpan perubahan.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);
    final nomor   = widget.permintaan['nomor_permintaan']?.toString() ?? '';
    final wajib   = InfoPrioritas.wajibCatatan(_prioritas);

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : Text(_revisi ? 'Revisi Permintaan' : 'Edit Permintaan'),
        backgroundColor: primary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [

          // ── Info & aturan ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _revisi ? Colors.blue.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _revisi ? Colors.blue.shade200 : Colors.grey.shade300),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nomor,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              if (_revisi &&
                  (widget.catatanKeputusan ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Catatan dari ${widget.tahapKeputusan ?? 'Admin'}:',
                    style: TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800)),
                const SizedBox(height: 2),
                Text(widget.catatanKeputusan!,
                    style: const TextStyle(fontSize: 13)),
              ],
              const SizedBox(height: 8),
              Text(
                _revisi
                    ? 'Anda merevisi permintaan yang sama (nomor tetap), '
                      'tidak perlu membuat permintaan baru.'
                    : 'Permintaan masih Pending sehingga masih bisa diubah.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                'Yang dapat diubah: jumlah barang, prioritas & catatan, atau '
                'menghapus barang. Barang baru tidak dapat ditambahkan.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ]),
          ),

          const SizedBox(height: 16),
          const Text('Barang yang Diminta',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),

          ..._baris.map(_kartuBarang),

          if (_baris.length == 1)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(
                _revisi
                    ? 'Minimal 1 barang harus tetap ada.'
                    : 'Minimal 1 barang harus tetap ada. Gunakan Batalkan '
                      'Permintaan bila tidak jadi meminta.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ),

          const SizedBox(height: 14),
          const Text('Prioritas & Catatan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),

          PrioritasSelector(
            selected : _prioritas,
            onChanged: (v) => setState(() => _prioritas = v),
          ),

          TextField(
            controller: _catatanCtrl,
            maxLines  : 3,
            maxLength : 500,
            onChanged : (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: wajib ? 'Catatan (wajib)' : 'Catatan (opsional)',
              filled   : true,
              fillColor: Colors.white,
              border   : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 14),

          ElevatedButton.icon(
            onPressed: (_menyimpan || !_adaPerubahan) ? null : _simpan,
            icon: _menyimpan
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Icon(_revisi ? Icons.send_rounded : Icons.save_outlined),
            label: Text(
              _menyimpan
                  ? 'Menyimpan...'
                  : (_revisi ? 'Kirim Ulang Revisi' : 'Simpan Perubahan'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (!_adaPerubahan)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Center(
                child: Text('Ubah sesuatu terlebih dahulu untuk menyimpan.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kartuBarang(_Baris b) {
    final kurangStok = b.jumlah > b.stok;

    return Container(
      margin : const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: kurangStok ? Colors.red.shade300 : Colors.grey.shade200),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56, height: 56,
            child: b.gambar.isNotEmpty
                ? Image.network(b.gambar, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.nama,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(b.kategori,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(
              kurangStok
                  ? 'Stok kini ${b.stok} ${b.satuan} — kurangi jumlah'
                  : 'Stok tersedia: ${b.stok} ${b.satuan}',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: kurangStok ? Colors.red.shade700 : Colors.green.shade700),
            ),
            const SizedBox(height: 8),
            Row(children: [
              QtyStepper(
                compact   : true,
                jumlah    : b.jumlah,
                max       : b.stok,
                min       : 1,
                satuan    : b.satuan,
                namaBarang: b.nama,
                onChanged : (v) => setState(() => b.jumlah = v),
              ),
              const SizedBox(width: 8),
              if (b.jumlah != b.jumlahAwal)
                Text('(semula ${b.jumlahAwal})',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const Spacer(),
              InkWell(
                onTap: _baris.length > 1 ? () => _hapus(b) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _baris.length > 1
                        ? Colors.red.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close,
                      size: 18,
                      color: _baris.length > 1 ? Colors.red : Colors.grey),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(AppConstants.primaryLightColor),
    alignment: Alignment.center,
    child: const Icon(Icons.inventory_2_outlined,
        size: 24, color: Color(AppConstants.primaryColor)),
  );
}
