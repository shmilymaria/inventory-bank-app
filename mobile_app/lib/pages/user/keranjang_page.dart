import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';
import 'package:inventori_bank/services/cart_service.dart';
import 'package:inventori_bank/utils/status_permintaan.dart';
import 'package:inventori_bank/widgets/prioritas_selector.dart';
import 'package:inventori_bank/widgets/qty_stepper.dart';

/// Keranjang permintaan.
/// Setelah permintaan terkirim, halaman ini menutup diri dan mengembalikan
/// {'id': ..., 'nomor': ...} supaya tab Ajukan membuka detail permintaan
/// tersebut di menu Riwayat.
class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});
  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  final CartService _cart = CartService.instance;

  String _prioritas = 'Normal';
  bool   _mengirim  = false;
  final TextEditingController _catatanCtrl = TextEditingController();

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
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

  Future<void> _kirim() async {
    final terpilih = _cart.terpilih;
    final catatan  = _catatanCtrl.text.trim();

    if (terpilih.isEmpty) {
      _snack('Centang minimal 1 barang yang akan diajukan.', isError: true);
      return;
    }
    if (InfoPrioritas.wajibCatatan(_prioritas) && catatan.isEmpty) {
      _snack('Catatan wajib diisi untuk prioritas $_prioritas.', isError: true);
      return;
    }

    setState(() => _mengirim = true);
    final res = await ApiService.post('/permintaan', {
      'prioritas': _prioritas,
      'catatan'  : catatan,
      'items'    : terpilih.map((i) => {
        'barang_id' : i.barangId,
        'jumlah'    : i.jumlah,
        'keterangan': '',
      }).toList(),
    });
    if (!mounted) return;
    setState(() => _mengirim = false);

    if (res['success'] == true && res['data'] != null) {
      // Hanya barang yang diajukan yang dikeluarkan dari keranjang
      _cart.hapusTerkirim(terpilih.map((i) => i.barangId));
      Navigator.pop(context, {
        'id'   : int.parse(res['data']['id'].toString()),
        'nomor': res['data']['nomor_permintaan']?.toString() ?? '',
      });
    } else {
      _snack(res['message'] ?? 'Gagal mengajukan permintaan.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return AnimatedBuilder(
      animation: _cart,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(AppConstants.bgColor),
          appBar: AppBar(
            title          : const Text('Keranjang Permintaan'),
            backgroundColor: primary,
          ),
          body: _cart.kosong ? _kosong() : _isi(),
          bottomNavigationBar: _cart.kosong ? null : _barBawah(),
        );
      },
    );
  }

  // ── Keranjang kosong ──────────────────────────────────────
  Widget _kosong() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
      const SizedBox(height: 12),
      const Text('Keranjang masih kosong.',
          style: TextStyle(color: Colors.grey, fontSize: 14)),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        child    : const Text('Kembali ke Katalog'),
      ),
    ]),
  );

  // ── Isi ───────────────────────────────────────────────────
  Widget _isi() {
    final items = _cart.items;
    final wajib = InfoPrioritas.wajibCatatan(_prioritas);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [

        // Pilih Semua
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: CheckboxListTile(
            value: _cart.semuaDipilih,
            onChanged: (v) => _cart.pilihSemua(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            title: const Text('Pilih Semua',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(
              '${_cart.terpilih.length} dari ${items.length} barang dipilih',
              style: const TextStyle(fontSize: 11.5),
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text('Daftar Barang yang Diminta',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),

        ...items.map(_barisBarang),

        const SizedBox(height: 18),
        const Text('Prioritas & Catatan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        Text('Pilih prioritas sesuai kebutuhan Anda.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 10),

        PrioritasSelector(
          selected : _prioritas,
          onChanged: (v) => setState(() => _prioritas = v),
        ),

        const SizedBox(height: 4),
        TextField(
          controller: _catatanCtrl,
          maxLines  : 3,
          maxLength : 500,
          onChanged : (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: wajib ? 'Catatan (wajib)' : 'Catatan (opsional)',
            hintText : wajib
                ? 'Jelaskan alasan / kebutuhan permintaan ini...'
                : 'Tambahkan catatan bila perlu...',
            filled   : true,
            fillColor: Colors.white,
            border   : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _barisBarang(CartItem i) {
    return Container(
      margin : const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(2, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: i.dipilih
              ? const Color(AppConstants.primaryColor).withOpacity(0.35)
              : Colors.grey.shade200,
        ),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(
          value    : i.dipilih,
          onChanged: (v) => _cart.setDipilih(i.barangId, v ?? false),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 56, height: 56,
            child: i.gambar.isNotEmpty
                ? Image.network(i.gambar, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.namaBarang,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(i.namaKategori,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text('Stok tersedia: ${i.stok} ${i.satuan}',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: Colors.green.shade700)),
            const SizedBox(height: 8),
            Row(children: [
              QtyStepper(
                compact   : true,
                jumlah    : i.jumlah,
                max       : i.stok,
                min       : 1,
                satuan    : i.satuan,
                namaBarang: i.namaBarang,
                onChanged : (v) => _cart.setJumlah(i.barangId, v),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _cart.hapus(i.barangId),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 18),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  // ── Tombol kirim (melekat di bawah) ───────────────────────
  Widget _barBawah() {
    final n = _cart.terpilih.length;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.08), blurRadius: 10)],
        ),
        child: ElevatedButton.icon(
          onPressed: _mengirim ? null : _kirim,
          icon: _mengirim
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.send_rounded),
          label: Text(
            _mengirim ? 'Mengirim...' : 'Kirim Permintaan ($n barang)',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: const Color(AppConstants.primaryLightColor),
    alignment: Alignment.center,
    child: const Icon(Icons.inventory_2_outlined,
        size: 24, color: Color(AppConstants.primaryColor)),
  );
}
