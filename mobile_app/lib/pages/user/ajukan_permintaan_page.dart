import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';

class AjukanPermintaanPage extends StatefulWidget {
  const AjukanPermintaanPage({super.key});
  @override
  State<AjukanPermintaanPage> createState() => _AjukanPermintaanPageState();
}

class _AjukanPermintaanPageState extends State<AjukanPermintaanPage> {
  // ── State — gunakan List<dynamic> agar tidak ada type conflict
  List<dynamic> _barang      = [];
  List<dynamic> _items       = [];
  String        _prioritas   = 'Normal';
  final TextEditingController _catatanCtrl = TextEditingController();
  bool          _loadingBarang = true;
  bool          _isSubmitting  = false;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  // ── Load daftar barang dari API ──────────────────────────
  Future<void> _loadBarang() async {
    setState(() => _loadingBarang = true);
    final res = await ApiService.get('/barang');

    if (res['success'] == true && res['data'] != null) {
      final List<dynamic> raw = res['data'] as List<dynamic>;
      final List<dynamic> parsed = raw.map((b) => {
        'id'           : int.parse(b['id'].toString()),
        'kode_barang'  : b['kode_barang'].toString(),
        'nama_barang'  : b['nama_barang'].toString(),
        'satuan'       : b['satuan'].toString(),
        'stok'         : int.parse(b['stok'].toString()),
        'status_barang': b['status_barang'].toString(),
        'nama_kategori': b['nama_kategori'].toString(),
      }).toList();

      setState(() {
        _barang        = parsed;
        _loadingBarang = false;
      });
    } else {
      setState(() => _loadingBarang = false);
      if (mounted) {
        _snack('Gagal memuat daftar barang.', isError: true);
      }
    }
  }

  // ── Ambil nilai int dari item map ────────────────────────
  int _intVal(dynamic item, String key) =>
      int.parse(item[key].toString());

  String _strVal(dynamic item, String key) =>
      item[key]?.toString() ?? '';

  // ── Tambah item baru ke daftar ───────────────────────────
  void _addItem() {
    if (_barang.isEmpty) {
      _snack('Data barang belum tersedia.', isError: true);
      return;
    }

    // Cari barang pertama yang belum dipilih
    dynamic barangPilihan = _barang[0];
    for (final b in _barang) {
      final sudahAda = _items.any(
          (i) => _intVal(i, 'barang_id') == _intVal(b, 'id'));
      if (!sudahAda) {
        barangPilihan = b;
        break;
      }
    }

    setState(() {
      _items.add({
        'barang_id'   : _intVal(barangPilihan, 'id'),
        'nama_barang' : _strVal(barangPilihan, 'nama_barang'),
        'satuan'      : _strVal(barangPilihan, 'satuan'),
        'stok'        : _intVal(barangPilihan, 'stok'),
        'nama_kategori': _strVal(barangPilihan, 'nama_kategori'),
        'jumlah'      : 1,
        'keterangan'  : '',
      });
    });
  }

  // ── Hapus item ───────────────────────────────────────────
  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  // ── Ganti barang yang dipilih ────────────────────────────
  void _onBarangChanged(int index, int barangId) {
    final b = _barang.firstWhere(
        (x) => _intVal(x, 'id') == barangId);
    setState(() {
      _items[index]['barang_id']    = _intVal(b, 'id');
      _items[index]['nama_barang']  = _strVal(b, 'nama_barang');
      _items[index]['satuan']       = _strVal(b, 'satuan');
      _items[index]['stok']         = _intVal(b, 'stok');
      _items[index]['nama_kategori']= _strVal(b, 'nama_kategori');
      final stok = _intVal(b, 'stok');
      if (_intVal(_items[index], 'jumlah') > stok) {
        _items[index]['jumlah'] = stok > 0 ? 1 : 1;
      }
    });
  }

  // ── Submit permintaan ────────────────────────────────────
  Future<void> _submit() async {
    if (_items.isEmpty) {
      _snack('Tambahkan minimal 1 barang terlebih dahulu.', isError: true);
      return;
    }
    for (final item in _items) {
      if (_intVal(item, 'jumlah') <= 0) {
        _snack('Jumlah barang "${_strVal(item, 'nama_barang')}" tidak valid.',
            isError: true);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final body = {
      'prioritas': _prioritas,
      'catatan'  : _catatanCtrl.text.trim(),
      'items'    : _items.map((i) => {
        'barang_id'  : _intVal(i, 'barang_id'),
        'jumlah'     : _intVal(i, 'jumlah'),
        'keterangan' : _strVal(i, 'keterangan'),
      }).toList(),
    };

    final res = await ApiService.post('/permintaan', body);
    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (res['success'] == true) {
      _snack(res['message'] ?? 'Permintaan berhasil diajukan!');
      setState(() {
        _items.clear();
        _prioritas = 'Normal';
        _catatanCtrl.clear();
      });
    } else {
      _snack(res['message'] ?? 'Gagal mengajukan permintaan.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior       : SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin  : const EdgeInsets.all(16),
      duration: Duration(seconds: isError ? 4 : 3),
    ));
  }

  // ════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      appBar: AppBar(
        title          : const Text('Ajukan Permintaan'),
        backgroundColor: primary,
        automaticallyImplyLeading: false,
      ),
      body: _loadingBarang
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat data barang...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _barang.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Tidak ada barang tersedia.',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadBarang,
                        icon : const Icon(Icons.refresh),
                        label: const Text('Muat Ulang'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Info
                      Container(
                        padding   : const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.primaryLightColor),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(AppConstants.primaryColor)
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline,
                              color: Color(AppConstants.primaryColor),
                              size : 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            '${_barang.length} barang tersedia. '
                            'Pilih barang dan tentukan jumlah yang dibutuhkan.',
                            style: const TextStyle(
                                fontSize: 12,
                                color   : Color(AppConstants.primaryColor)),
                          )),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // Prioritas & Catatan
                      _sectionCard(
                        title: 'Prioritas & Catatan',
                        icon : Icons.flag_outlined,
                        child: Column(children: [
                          DropdownButtonFormField<String>(
                            value    : _prioritas,
                            decoration: InputDecoration(
                              labelText : 'Prioritas',
                              prefixIcon: const Icon(Icons.flag_outlined),
                              border    : OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide  : const BorderSide(
                                    color: primary, width: 2),
                              ),
                            ),
                            items: ['Normal', 'Penting', 'Mendesak']
                                .map((p) => DropdownMenuItem(
                                    value: p, child: Text(p)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _prioritas = v!),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller : _catatanCtrl,
                            maxLines   : 3,
                            decoration : InputDecoration(
                              labelText : 'Catatan (opsional)',
                              hintText  : 'Tambahkan catatan atau alasan permintaan...',
                              prefixIcon: const Icon(Icons.note_outlined),
                              border    : OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide  : const BorderSide(
                                    color: primary, width: 2),
                              ),
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // Daftar Barang
                      _sectionCard(
                        title: 'Daftar Barang yang Diminta'
                            '${_items.isNotEmpty ? " (${_items.length})" : ""}',
                        icon : Icons.shopping_cart_outlined,
                        child: Column(children: [

                          if (_items.isNotEmpty) ...[
                            ...List.generate(
                                _items.length,
                                (i) => _itemRow(i, _items[i])),
                            const SizedBox(height: 8),
                          ],

                          if (_items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child  : Column(children: [
                                Icon(Icons.add_shopping_cart_outlined,
                                    size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Belum ada barang ditambahkan.',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                                Text('Tap tombol di bawah untuk menambahkan.',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ]),
                            ),

                          const SizedBox(height: 8),

                          OutlinedButton.icon(
                            onPressed: _addItem,
                            icon     : const Icon(Icons.add_circle_outline),
                            label    : Text(_items.isEmpty
                                ? 'Tambah Barang'
                                : 'Tambah Barang Lagi'),
                            style: OutlinedButton.styleFrom(
                              minimumSize    : const Size(double.infinity, 48),
                              foregroundColor: primary,
                              side           : const BorderSide(color: primary),
                              shape          : RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      // Tombol Submit
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon     : _isSubmitting
                            ? const SizedBox(
                                width : 18, height: 18,
                                child : CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSubmitting
                              ? 'Mengirim...' : 'Ajukan Permintaan',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Permintaan akan dikirim ke Pimpinan untuk disetujui.',
                          style   : TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  // ── Widget: satu baris item barang ───────────────────────
  Widget _itemRow(int index, dynamic item) {
    final stok   = _intVal(item, 'stok');
    final jumlah = _intVal(item, 'jumlah');

    return Container(
      margin    : const EdgeInsets.only(bottom: 12),
      padding   : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(AppConstants.primaryColor).withOpacity(0.2)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Header baris
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Barang ${index + 1}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13,
                  color     : Color(AppConstants.primaryColor))),
          InkWell(
            onTap: () => _removeItem(index),
            child: Container(
              padding   : const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color       : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.close, color: Colors.red, size: 18),
            ),
          ),
        ]),

        const SizedBox(height: 10),

        // Dropdown barang
        DropdownButtonFormField<int>(
          value    : _intVal(item, 'barang_id'),
          isExpanded: true,
          decoration: InputDecoration(
            labelText  : 'Pilih Barang',
            prefixIcon : const Icon(Icons.inventory_2_outlined, size: 20),
            border     : OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide  : const BorderSide(
                  color: Color(AppConstants.primaryColor), width: 2),
            ),
            filled     : true,
            fillColor  : const Color(AppConstants.bgColor),
            isDense    : true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 14),
          ),
          items: _barang.map<DropdownMenuItem<int>>((b) {
            final bId       = _intVal(b, 'id');
            final isChosen  = _items.asMap().entries.any((e) =>
                e.key != index &&
                _intVal(e.value, 'barang_id') == bId);
            return DropdownMenuItem<int>(
              value  : bId,
              enabled: !isChosen,
              child  : Text(
                '${_strVal(b, 'nama_barang')} — '
                'Stok: ${_intVal(b, 'stok')} ${_strVal(b, 'satuan')}',
                overflow: TextOverflow.ellipsis,
                style   : TextStyle(
                    fontSize: 13,
                    color   : isChosen ? Colors.grey : Colors.black87),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) _onBarangChanged(index, v);
          },
        ),

        const SizedBox(height: 8),

        // Info kategori & stok
        Row(children: [
          const Icon(Icons.category_outlined,
              size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(_strVal(item, 'nama_kategori'),
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(width: 12),
          Icon(Icons.layers_outlined,
              size : 13,
              color: stok > 0 ? Colors.grey : Colors.red),
          const SizedBox(width: 4),
          Text('Stok: $stok ${_strVal(item, 'satuan')}',
              style: TextStyle(
                  fontSize: 11,
                  color   : stok > 0 ? Colors.grey : Colors.red)),
        ]),

        const SizedBox(height: 12),

        // Kontrol jumlah
        Row(children: [
          const Text('Jumlah:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(width: 12),

          // Tombol kurang
          GestureDetector(
            onTap: () {
              if (jumlah > 1) setState(() => _items[index]['jumlah']--);
            },
            child: Container(
              width : 36, height: 36,
              decoration: BoxDecoration(
                color       : jumlah > 1
                    ? const Color(AppConstants.primaryLightColor)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: jumlah > 1
                        ? const Color(AppConstants.primaryColor)
                            .withOpacity(0.4)
                        : Colors.grey.shade300),
              ),
              child: Icon(Icons.remove,
                  size : 18,
                  color: jumlah > 1
                      ? const Color(AppConstants.primaryColor)
                      : Colors.grey),
            ),
          ),

          // Tampilan jumlah
          Container(
            margin : const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color       : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(AppConstants.primaryColor)
                      .withOpacity(0.4)),
            ),
            child: Text('$jumlah',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16,
                    color     : Color(AppConstants.primaryColor))),
          ),

          // Tombol tambah
          GestureDetector(
            onTap: () {
              if (jumlah < stok) {
                setState(() => _items[index]['jumlah']++);
              } else {
                _snack(
                    'Jumlah tidak boleh melebihi stok tersedia ($stok).',
                    isError: true);
              }
            },
            child: Container(
              width : 36, height: 36,
              decoration: BoxDecoration(
                color       : const Color(AppConstants.primaryLightColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(AppConstants.primaryColor)
                        .withOpacity(0.4)),
              ),
              child: const Icon(Icons.add,
                  size : 18,
                  color: Color(AppConstants.primaryColor)),
            ),
          ),

          const SizedBox(width: 10),
          Text(_strVal(item, 'satuan'),
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ]),

        const SizedBox(height: 10),

        // Keterangan item
        TextField(
          decoration: InputDecoration(
            labelText     : 'Keterangan item (opsional)',
            hintText      : 'Contoh: Untuk keperluan rapat',
            border        : OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            isDense       : true,
            filled        : true,
            fillColor     : const Color(AppConstants.bgColor),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
          ),
          style    : const TextStyle(fontSize: 13),
          onChanged: (v) => _items[index]['keterangan'] = v,
        ),
      ]),
    );
  }

  // ── Widget: section card wrapper ─────────────────────────
  Widget _sectionCard({
    required String   title,
    required IconData icon,
    required Widget   child,
  }) {
    return Container(
      width     : double.infinity,
      padding   : const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon,
                color: const Color(AppConstants.primaryColor), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ]),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }
}