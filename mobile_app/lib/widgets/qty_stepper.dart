import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inventori_bank/constants/app_constants.dart';

/// Pengatur jumlah: (-)  n  (+).
///  - ketuk angka → dialog keyboard numerik untuk mengetik jumlah langsung
///  - [min] = 0 → tombol (-) pada angka 1 menghilangkan barang (dipakai di katalog)
///  - [min] = 1 → jumlah tidak bisa kurang dari 1 (dipakai di keranjang/edit)
///  - [max] = batas (stok tersedia)
class QtyStepper extends StatelessWidget {
  final int  jumlah;
  final int  max;
  final int  min;
  final String satuan;
  final String namaBarang;
  final bool compact;
  final ValueChanged<int> onChanged;

  const QtyStepper({
    super.key,
    required this.jumlah,
    required this.max,
    required this.onChanged,
    this.min        = 1,
    this.satuan     = '',
    this.namaBarang = '',
    this.compact    = false,
  });

  Future<void> _ketikManual(BuildContext context) async {
    final ctrl = TextEditingController(text: '$jumlah');
    ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
    String? error;

    final hasil = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          void kirim() {
            final v = int.tryParse(ctrl.text.trim());
            if (v == null) {
              setDialog(() => error = 'Masukkan angka yang valid.');
            } else if (v > max) {
              setDialog(() => error = 'Maksimal $max $satuan (stok tersedia).');
            } else if (v < min) {
              setDialog(() => error = 'Minimal $min.');
            } else {
              Navigator.pop(ctx, v);
            }
          }

          return AlertDialog(
            title: Text(namaBarang.isEmpty ? 'Ubah Jumlah' : namaBarang,
                style: const TextStyle(fontSize: 16)),
            content: TextField(
              controller     : ctrl,
              autofocus      : true,
              keyboardType   : TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength      : 6,
              decoration     : InputDecoration(
                labelText : 'Jumlah',
                helperText: 'Stok tersedia: $max $satuan',
                suffixText: satuan,
                errorText : error,
                border    : const OutlineInputBorder(),
              ),
              onSubmitted: (_) => kirim(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child    : const Text('Batal'),
              ),
              ElevatedButton(onPressed: kirim, child: const Text('Simpan')),
            ],
          );
        },
      ),
    );

    if (hasil != null) onChanged(hasil);
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);
    final ukuran  = compact ? 30.0 : 34.0;

    Widget tombol(IconData ikon, bool aktif, VoidCallback aksi) => InkWell(
      onTap: aktif ? aksi : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width : ukuran,
        height: ukuran,
        decoration: BoxDecoration(
          color: aktif
              ? const Color(AppConstants.primaryLightColor)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: aktif ? primary.withOpacity(0.4) : Colors.grey.shade300),
        ),
        child: Icon(ikon, size: 16, color: aktif ? primary : Colors.grey),
      ),
    );

    return Row(mainAxisSize: MainAxisSize.min, children: [
      tombol(Icons.remove, jumlah > min, () => onChanged(jumlah - 1)),
      InkWell(
        onTap: () => _ketikManual(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: BoxConstraints(minWidth: compact ? 34 : 44),
          margin     : const EdgeInsets.symmetric(horizontal: 6),
          padding    : EdgeInsets.symmetric(
              horizontal: 8, vertical: compact ? 5 : 6),
          decoration : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primary.withOpacity(0.4)),
          ),
          child: Text('$jumlah',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize  : compact ? 13 : 15,
                  color     : primary)),
        ),
      ),
      tombol(Icons.add, jumlah < max, () => onChanged(jumlah + 1)),
    ]);
  }
}
