import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/auth_service.dart';

/// Satu barang di keranjang permintaan.
class CartItem {
  final int    barangId;
  final String kodeBarang;
  final String namaBarang;
  final String namaKategori;
  final String satuan;
  final String gambar;   // URL penuh (sudah di-resolve), boleh kosong
  int  stok;             // stok terakhir yang diketahui → batas jumlah
  int  jumlah;
  bool dipilih;          // dicentang untuk diajukan

  CartItem({
    required this.barangId,
    required this.kodeBarang,
    required this.namaBarang,
    required this.namaKategori,
    required this.satuan,
    required this.gambar,
    required this.stok,
    required this.jumlah,
    this.dipilih = true,
  });

  Map<String, dynamic> toJson() => {
    'barang_id'    : barangId,
    'kode_barang'  : kodeBarang,
    'nama_barang'  : namaBarang,
    'nama_kategori': namaKategori,
    'satuan'       : satuan,
    'gambar'       : gambar,
    'stok'         : stok,
    'jumlah'       : jumlah,
    'dipilih'      : dipilih,
  };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
    barangId    : int.parse(j['barang_id'].toString()),
    kodeBarang  : j['kode_barang']?.toString()   ?? '',
    namaBarang  : j['nama_barang']?.toString()   ?? '',
    namaKategori: j['nama_kategori']?.toString() ?? '',
    satuan      : j['satuan']?.toString()        ?? '',
    gambar      : j['gambar']?.toString()        ?? '',
    stok        : int.tryParse(j['stok'].toString())   ?? 0,
    jumlah      : int.tryParse(j['jumlah'].toString()) ?? 1,
    dipilih     : j['dipilih'] != false,
  );
}

/// Keranjang permintaan User.
///  - dipakai bersama oleh tab Ajukan (katalog) dan halaman Keranjang
///  - tersimpan di HP per akun, jadi tidak hilang saat aplikasi ditutup
///  - barang yang tidak dicentang saat "Kirim Permintaan" tetap tinggal
class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  final List<CartItem> _items = [];
  int _userId = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get kosong      => _items.isEmpty;
  int  get totalJenis  => _items.length;
  int  get totalUnit   => _items.fold(0, (a, b) => a + b.jumlah);

  List<CartItem> get terpilih => _items.where((i) => i.dipilih).toList();
  bool get semuaDipilih => _items.isNotEmpty && _items.every((i) => i.dipilih);

  CartItem? cari(int barangId) {
    for (final i in _items) {
      if (i.barangId == barangId) return i;
    }
    return null;
  }

  int jumlahDi(int barangId) => cari(barangId)?.jumlah ?? 0;

  // ── Penyimpanan ───────────────────────────────────────────
  String get _kunci => 'cart_user_$_userId';

  /// Muat keranjang milik akun yang sedang login (mengganti isi memori,
  /// sehingga keranjang akun lain tidak ikut terbawa).
  Future<void> muat() async {
    final u = await AuthService.getUserData();
    _userId = int.tryParse(u['user_id'].toString()) ?? 0;

    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_kunci);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        for (final e in list) {
          _items.add(CartItem.fromJson(Map<String, dynamic>.from(e)));
        }
      } catch (_) {
        // data rusak → abaikan, mulai dari keranjang kosong
      }
    }
    notifyListeners();
  }

  Future<void> _simpan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kunci, jsonEncode(_items.map((e) => e.toJson()).toList()));
  }

  void _berubah() {
    notifyListeners();
    _simpan();
  }

  // ── Operasi ───────────────────────────────────────────────
  /// Tambah dari katalog (jumlah awal 1). Mengembalikan false bila stok habis.
  bool tambah(Map<String, dynamic> barang) {
    final stok = int.tryParse(barang['stok'].toString()) ?? 0;
    if (stok <= 0) return false;

    final id = int.parse(barang['id'].toString());
    final ada = cari(id);
    if (ada != null) {
      if (ada.jumlah < ada.stok) ada.jumlah++;
    } else {
      _items.add(CartItem(
        barangId    : id,
        kodeBarang  : barang['kode_barang']?.toString()   ?? '',
        namaBarang  : barang['nama_barang']?.toString()   ?? '',
        namaKategori: barang['nama_kategori']?.toString() ?? '',
        satuan      : barang['satuan']?.toString()        ?? '',
        gambar      : AppConstants.resolveImageUrl(barang['gambar']?.toString()),
        stok        : stok,
        jumlah      : 1,
      ));
    }
    _berubah();
    return true;
  }

  /// Atur jumlah. 0 (atau kurang) menghapus barang dari keranjang.
  void setJumlah(int barangId, int jumlah) {
    final i = cari(barangId);
    if (i == null) return;
    if (jumlah <= 0) {
      _items.remove(i);
    } else {
      i.jumlah = jumlah > i.stok ? i.stok : jumlah;
    }
    _berubah();
  }

  void hapus(int barangId) {
    _items.removeWhere((e) => e.barangId == barangId);
    _berubah();
  }

  void setDipilih(int barangId, bool nilai) {
    final i = cari(barangId);
    if (i == null) return;
    i.dipilih = nilai;
    _berubah();
  }

  void pilihSemua(bool nilai) {
    for (final i in _items) {
      i.dipilih = nilai;
    }
    _berubah();
  }

  /// Dipanggil setelah permintaan terkirim: hapus HANYA barang yang diajukan.
  void hapusTerkirim(Iterable<int> barangIds) {
    final set = barangIds.toSet();
    _items.removeWhere((e) => set.contains(e.barangId));
    _berubah();
  }

  /// Sinkronkan dengan katalog terbaru: perbarui stok, batasi jumlah ke stok,
  /// dan buang barang yang sudah habis/tidak ada lagi.
  void sinkronStok(List<dynamic> katalog) {
    final stokMap = <int, int>{
      for (final b in katalog)
        int.parse(b['id'].toString()): int.tryParse(b['stok'].toString()) ?? 0,
    };

    var berubah = false;
    _items.removeWhere((i) {
      final stok = stokMap[i.barangId];
      if (stok == null || stok <= 0) {
        berubah = true;
        return true;
      }
      if (stok != i.stok) {
        i.stok = stok;
        berubah = true;
      }
      if (i.jumlah > stok) {
        i.jumlah = stok;
        berubah = true;
      }
      return false;
    });

    if (berubah) _berubah();
  }
}
