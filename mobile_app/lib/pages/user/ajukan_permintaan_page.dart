import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/services/cart_service.dart';
import 'package:inventori_bank/widgets/qty_stepper.dart';
import 'package:inventori_bank/pages/user/keranjang_page.dart';
import 'package:inventori_bank/pages/user/user_main_page.dart';

/// Tab "Ajukan": katalog barang + keranjang permintaan.
/// State dibuat public supaya Beranda bisa membuka katalog dengan
/// kelompok kategori tertentu (lihat [setKelompok]).
class AjukanPermintaanPage extends StatefulWidget {
  const AjukanPermintaanPage({super.key});
  @override
  State<AjukanPermintaanPage> createState() => AjukanPermintaanPageState();
}

class AjukanPermintaanPageState extends State<AjukanPermintaanPage> {
  final CartService _cart = CartService.instance;

  // Kelompok kategori: key sama dengan `kelompok_kategori` dari API.
  static const List<List<String>> _kelompokList = [
    ['',               'Semua'],
    ['ATK',            'Alat Tulis Kantor (ATK)'],
    ['Barang Cetakan', 'Barang Cetakan'],
    ['Barang Lainnya', 'Barang Lainnya'],
  ];

  List<dynamic> _barang   = [];
  String        _kelompok = '';
  bool          _loading  = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Dipanggil dari Beranda (tombol kategori) → tampilkan kelompok tsb.
  void setKelompok(String? kelompok) {
    setState(() {
      _kelompok = kelompok ?? '';
      _searchCtrl.clear();
    });
  }

  Future<void> _load() async {
    final res = await ApiService.get('/barang');
    if (!mounted) return;

    final data = res['success'] == true ? (res['data'] as List? ?? []) : <dynamic>[];
    setState(() {
      _barang  = data;
      _loading = false;
    });
    // stok bisa berubah sejak barang dimasukkan ke keranjang
    if (data.isNotEmpty) _cart.sinkronStok(data);

    if (res['success'] != true && mounted) {
      _snack(res['message'] ?? 'Gagal memuat katalog barang.', isError: true);
    }
  }

  // Cadangan bila API lama belum mengirim kelompok_kategori
  String _kelompokDari(dynamic b) {
    final k = b['kelompok_kategori']?.toString();
    if (k != null && k.isNotEmpty) return k;
    final nama = (b['nama_kategori'] ?? '').toString();
    if (nama == 'Alat Tulis Kantor') return 'ATK';
    if (nama == 'Barang Cetakan')    return 'Barang Cetakan';
    return 'Barang Lainnya';
  }

  List<dynamic> get _tampil {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _barang.where((b) {
      if (_kelompok.isNotEmpty && _kelompokDari(b) != _kelompok) return false;
      if (q.isEmpty) return true;
      final nama = (b['nama_barang'] ?? '').toString().toLowerCase();
      final kode = (b['kode_barang'] ?? '').toString().toLowerCase();
      return nama.contains(q) || kode.contains(q);
    }).toList();
  }

  Future<void> _bukaKeranjang() async {
    final hasil = await Navigator.push<Map<String, dynamic>>(
        context, MaterialPageRoute(builder: (_) => const KeranjangPage()));
    if (!mounted) return;

    if (hasil != null) {
      // Permintaan terkirim → langsung buka detailnya di menu Riwayat
      context.findAncestorStateOfType<UserMainPageState>()
          ?.goToRiwayatDetail(hasil['id'] as int, hasil['nomor'].toString());
    }
    _load();
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

    return AnimatedBuilder(
      animation: _cart,
      builder: (context, _) {
        final tampil = _tampil;

        return Scaffold(
          backgroundColor: const Color(AppConstants.bgColor),
          appBar: AppBar(
            title          : const Text('Ajukan Permintaan'),
            backgroundColor: primary,
            automaticallyImplyLeading: false,
          ),
          // FAB keranjang — hanya muncul bila sudah ada barang
          floatingActionButton: _cart.kosong
              ? null
              : FloatingActionButton.extended(
                  onPressed      : _bukaKeranjang,
                  backgroundColor: primary,
                  icon: Badge(
                    label: Text('${_cart.totalJenis}'),
                    child: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white),
                  ),
                  label: const Text('Keranjang',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                ),
          body: Column(children: [

            // ── Pencarian ───────────────────────────────
            Container(
              color  : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child  : TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText  : 'Cari nama atau kode barang...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: _searchCtrl.clear,
                        )
                      : null,
                  filled   : true,
                  fillColor: const Color(AppConstants.bgColor),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide  : BorderSide.none,
                  ),
                ),
              ),
            ),

            // ── Kelompok kategori ───────────────────────
            Container(
              color  : Colors.white,
              padding: const EdgeInsets.only(left: 16, bottom: 10),
              child  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _kelompokList.map((k) {
                    final aktif = _kelompok == k[0];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child  : ChoiceChip(
                        label   : Text(k[1]),
                        selected: aktif,
                        onSelected: (_) => setState(() => _kelompok = k[0]),
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

            // ── Katalog ─────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      color    : primary,
                      child    : CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                            sliver : SliverToBoxAdapter(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Katalog Barang',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize  : 15)),
                                  Text('${tampil.length} barang',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                          if (tampil.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 52, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text(
                                      _barang.isEmpty
                                          ? 'Belum ada barang.'
                                          : 'Barang tidak ditemukan.',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                              sliver : SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount  : 2,
                                  childAspectRatio: 0.66,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing : 12,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => _kartu(tampil[i]),
                                  childCount: tampil.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ]),
        );
      },
    );
  }

  // ── Kartu barang ──────────────────────────────────────────
  Widget _kartu(dynamic b) {
    final id     = int.parse(b['id'].toString());
    final stok   = int.tryParse(b['stok'].toString()) ?? 0;
    final habis  = stok <= 0;
    final gambar = AppConstants.resolveImageUrl(b['gambar']?.toString());
    final satuan = b['satuan']?.toString() ?? '';
    final jml    = _cart.jumlahDi(id);

    Widget gambarBarang = SizedBox(
      width : double.infinity,
      height: double.infinity,
      child : gambar.isNotEmpty
          ? Image.network(gambar, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder())
          : _placeholder(),
    );

    // Stok habis → abu-abu
    if (habis) {
      gambarBarang = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: gambarBarang,
      );
    }

    return Opacity(
      opacity: habis ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: jml > 0
                  ? const Color(AppConstants.primaryColor)
                  : Colors.grey.shade200,
              width: jml > 0 ? 1.4 : 1),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Expanded(
            child: Stack(children: [
              Positioned.fill(child: gambarBarang),
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
                              color: Colors.white, fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b['nama_barang']?.toString() ?? '',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(b['nama_kategori']?.toString() ?? '',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(
                habis ? 'Stok habis' : 'Stok: $stok $satuan',
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: habis ? Colors.red.shade400 : Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 6),

              // Kanan bawah: tombol (+) → berubah jadi (-) n (+)
              Align(
                alignment: Alignment.centerRight,
                child: habis
                    ? _tombolTambah(null)
                    : (jml == 0
                        ? _tombolTambah(() {
                            if (!_cart.tambah(Map<String, dynamic>.from(b))) {
                              _snack('Stok barang ini sedang habis.',
                                  isError: true);
                            }
                          })
                        : QtyStepper(
                            compact   : true,
                            jumlah    : jml,
                            max       : stok,
                            min       : 0, // (-) pada angka 1 → keluar dari keranjang
                            satuan    : satuan,
                            namaBarang: b['nama_barang']?.toString() ?? '',
                            onChanged : (v) => _cart.setJumlah(id, v),
                          )),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tombolTambah(VoidCallback? aksi) => InkWell(
    onTap: aksi,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: aksi == null
            ? Colors.grey.shade300
            : const Color(AppConstants.primaryColor),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.add, size: 18,
          color: aksi == null ? Colors.grey.shade600 : Colors.white),
    ),
  );

  Widget _placeholder() => Container(
    color: const Color(AppConstants.primaryLightColor),
    alignment: Alignment.center,
    child: const Icon(Icons.inventory_2_outlined,
        size: 36, color: Color(AppConstants.primaryColor)),
  );
}
