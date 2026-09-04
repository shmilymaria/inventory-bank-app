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
  List<dynamic> _barang         = [];   // seluruh katalog barang dari API
  List<dynamic> _filteredBarang = [];   // hasil filter pencarian
  List<dynamic> _items          = [];   // daftar barang yang diminta (cart)
  String        _prioritas      = 'Normal';
  final TextEditingController _catatanCtrl = TextEditingController();
  final TextEditingController _searchCtrl  = TextEditingController();
  bool          _loadingBarang  = true;
  bool          _isSubmitting   = false;

  @override
  void initState() {
    super.initState();
    _loadBarang();
    _searchCtrl.addListener(_onSearchChanged);
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
        // Catatan: nama field gambar di API belum dipastikan, jadi kita
        // coba beberapa kemungkinan nama field yang umum dipakai.
        // Sesuaikan key di bawah ini dengan field asli dari response
        // /barang di backend Laravel Anda jika berbeda.
        'gambar': AppConstants.resolveImageUrl(
          (b['gambar'] ?? b['foto'] ?? b['image'] ?? b['foto_barang'])
              ?.toString(),
        ),
      }).toList();

      setState(() {
        _barang         = parsed;
        _filteredBarang = parsed;
        _loadingBarang  = false;
      });
    } else {
      setState(() => _loadingBarang = false);
      if (mounted) {
        _snack('Gagal memuat daftar barang.', isError: true);
      }
    }
  }

  // ── Ambil nilai dari item map ─────────────────────────────
  int _intVal(dynamic item, String key) =>
      int.parse(item[key].toString());

  String _strVal(dynamic item, String key) =>
      item[key]?.toString() ?? '';

  // ── Filter pencarian barang ───────────────────────────────
  void _onSearchChanged() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBarang = _barang;
      } else {
        _filteredBarang = _barang.where((b) {
          final nama     = _strVal(b, 'nama_barang').toLowerCase();
          final kode     = _strVal(b, 'kode_barang').toLowerCase();
          final kategori = _strVal(b, 'nama_kategori').toLowerCase();
          return nama.contains(query) ||
              kode.contains(query) ||
              kategori.contains(query);
        }).toList();
      }
    });
  }

  // ── Cari index item di cart berdasarkan barang_id ────────
  int _cartIndexOf(int barangId) =>
      _items.indexWhere((i) => _intVal(i, 'barang_id') == barangId);

  // ── Tambah barang dari katalog ke cart ────────────────────
  void _addToCart(dynamic barang) {
    final stok = _intVal(barang, 'stok');
    if (stok <= 0) {
      _snack('Stok "${_strVal(barang, 'nama_barang')}" sedang habis.',
          isError: true);
      return;
    }

    final barangId  = _intVal(barang, 'id');
    final idxInCart = _cartIndexOf(barangId);

    setState(() {
      if (idxInCart == -1) {
        _items.add({
          'barang_id'    : barangId,
          'nama_barang'  : _strVal(barang, 'nama_barang'),
          'satuan'       : _strVal(barang, 'satuan'),
          'stok'         : stok,
          'nama_kategori': _strVal(barang, 'nama_kategori'),
          'gambar'       : _strVal(barang, 'gambar'),
          'jumlah'       : 1,
          'keterangan'   : '',
        });
      } else {
        final jumlahSaatIni = _intVal(_items[idxInCart], 'jumlah');
        if (jumlahSaatIni < stok) {
          _items[idxInCart]['jumlah'] = jumlahSaatIni + 1;
        } else {
          _snack('Jumlah tidak boleh melebihi stok tersedia ($stok).',
              isError: true);
        }
      }
    });
  }

  // ── Hapus item dari cart ──────────────────────────────────
  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
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
              : Column(
                  children: [
                    // ── Search bar (sticky di atas) ───────────
                    Container(
                      width  : double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      color  : Colors.white,
                      child  : TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Cari nama barang, kode, atau kategori...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () => _searchCtrl.clear(),
                                )
                              : null,
                          filled : true,
                          fillColor: const Color(AppConstants.bgColor),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide  : BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child  : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── Katalog barang (grid ala e-commerce) ──
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Katalog Barang',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize  : 15)),
                                Text(
                                  '${_filteredBarang.length} barang',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            _filteredBarang.isEmpty
                                ? Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 40),
                                    child: Center(
                                      child: Column(children: [
                                        Icon(Icons.search_off,
                                            size: 48,
                                            color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Barang "${_searchCtrl.text}" tidak ditemukan.',
                                          style: const TextStyle(
                                              color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                      ]),
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount : 2,
                                      childAspectRatio: 0.66,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing : 12,
                                    ),
                                    itemCount: _filteredBarang.length,
                                    itemBuilder: (context, index) =>
                                        _catalogCard(_filteredBarang[index]),
                                  ),

                            const SizedBox(height: 20),

                            // ── Prioritas & Catatan ──────────────
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

                            // ── Daftar Barang yang Diminta (cart) ──
                            _sectionCard(
                              title: 'Daftar Barang yang Diminta'
                                  '${_items.isNotEmpty ? " (${_items.length})" : ""}',
                              icon : Icons.shopping_cart_outlined,
                              child: Column(children: [
                                if (_items.isNotEmpty)
                                  ...List.generate(
                                      _items.length,
                                      (i) => _cartRow(i, _items[i])),

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
                                      Text(
                                          'Tap barang pada katalog di atas untuk menambahkan.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Colors.grey, fontSize: 12)),
                                    ]),
                                  ),
                              ]),
                            ),

                            const SizedBox(height: 24),

                            // ── Tombol Submit ─────────────────────
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // ── Widget: kartu katalog barang (ala e-commerce) ─────────
  Widget _catalogCard(dynamic barang) {
    final stok      = _intVal(barang, 'stok');
    final habis     = stok <= 0;
    final gambar    = _strVal(barang, 'gambar');
    final barangId  = _intVal(barang, 'id');
    final idxInCart = _cartIndexOf(barangId);
    final jumlahDiCart =
        idxInCart == -1 ? 0 : _intVal(_items[idxInCart], 'jumlah');

    return Opacity(
      opacity: habis ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: jumlahDiCart > 0
                  ? const Color(AppConstants.primaryColor)
                  : Colors.grey.shade200,
              width: jumlahDiCart > 0 ? 1.4 : 1),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Gambar barang
            Expanded(
              child: Stack(
                children: [
                  ColorFiltered(
                    colorFilter: habis
                        ? const ColorFilter.matrix(<double>[
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0,      0,      0,      1, 0,
                          ])
                        : const ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply),
                    child: SizedBox(
                      width : double.infinity,
                      height: double.infinity,
                      child : gambar.isNotEmpty
                          ? Image.network(
                              gambar,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _catalogImagePlaceholder(),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(
                                    child: SizedBox(
                                      width : 22, height: 22,
                                      child : CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                );
                              },
                            )
                          : _catalogImagePlaceholder(),
                    ),
                  ),

                  // Badge "Stok Habis"
                  if (habis)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.25),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Stok Habis',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),

                  // Badge jumlah di cart
                  if (!habis && jumlahDiCart > 0)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(AppConstants.primaryColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$jumlahDiCart di keranjang',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),

            // Info barang
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _strVal(barang, 'nama_barang'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _strVal(barang, 'nama_kategori'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        habis
                            ? 'Stok habis'
                            : 'Stok: $stok ${_strVal(barang, 'satuan')}',
                        style: TextStyle(
                          fontSize  : 11,
                          fontWeight: FontWeight.w600,
                          color     : habis
                              ? Colors.red.shade400
                              : Colors.green.shade700,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: habis ? null : () => _addToCart(barang),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: habis
                                ? Colors.grey.shade300
                                : const Color(AppConstants.primaryColor),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            size : 16,
                            color: habis ? Colors.grey.shade600 : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _catalogImagePlaceholder() {
    return Container(
      color: const Color(AppConstants.primaryLightColor),
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined,
          size: 36, color: Color(AppConstants.primaryColor)),
    );
  }

  // ── Widget: satu baris item di cart / daftar diminta ──────
  Widget _cartRow(int index, dynamic item) {
    final stok    = _intVal(item, 'stok');
    final jumlah  = _intVal(item, 'jumlah');
    final gambar  = _strVal(item, 'gambar');

    return Container(
      margin    : const EdgeInsets.only(bottom: 12),
      padding   : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(AppConstants.primaryColor).withOpacity(0.2)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: [
          // Thumbnail kecil
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width : 44, height: 44,
              child : gambar.isNotEmpty
                  ? Image.network(
                      gambar,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(AppConstants.primaryLightColor),
                        child: const Icon(Icons.inventory_2_outlined,
                            size: 20, color: Color(AppConstants.primaryColor)),
                      ),
                    )
                  : Container(
                      color: const Color(AppConstants.primaryLightColor),
                      child: const Icon(Icons.inventory_2_outlined,
                          size: 20, color: Color(AppConstants.primaryColor)),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_strVal(item, 'nama_barang'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.category_outlined,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text(_strVal(item, 'nama_kategori'),
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  const SizedBox(width: 10),
                  Icon(Icons.layers_outlined,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 3),
                  Text('Stok: $stok ${_strVal(item, 'satuan')}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
              ],
            ),
          ),
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

        // Kontrol jumlah
        Row(children: [
          const Text('Jumlah:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(width: 12),

          GestureDetector(
            onTap: () {
              if (jumlah > 1) setState(() => _items[index]['jumlah']--);
            },
            child: Container(
              width : 34, height: 34,
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
                  size : 16,
                  color: jumlah > 1
                      ? const Color(AppConstants.primaryColor)
                      : Colors.grey),
            ),
          ),

          Container(
            margin : const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color       : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(AppConstants.primaryColor)
                      .withOpacity(0.4)),
            ),
            child: Text('$jumlah',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15,
                    color     : Color(AppConstants.primaryColor))),
          ),

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
              width : 34, height: 34,
              decoration: BoxDecoration(
                color       : const Color(AppConstants.primaryLightColor),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(AppConstants.primaryColor)
                        .withOpacity(0.4)),
              ),
              child: const Icon(Icons.add,
                  size : 16,
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
          controller: TextEditingController(text: _strVal(item, 'keterangan'))
            ..selection = TextSelection.collapsed(
                offset: _strVal(item, 'keterangan').length),
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
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }
}