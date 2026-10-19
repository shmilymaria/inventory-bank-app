import 'package:flutter/material.dart';
import 'package:inventori_bank/utils/status_permintaan.dart';

/// Pilihan prioritas berbentuk kartu (selectable cards) lengkap dengan
/// ketentuan, supaya User tahu prioritas mana yang tepat:
///   Normal   → diproses Admin (tanpa Pimpinan), catatan opsional
///   Mendesak → diproses Admin (tanpa Pimpinan), catatan wajib
///   Penting  → butuh persetujuan Pimpinan,      catatan wajib
class PrioritasSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const PrioritasSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: InfoPrioritas.daftar.map((p) {
        final pilih = p.nama == selected;
        final warna = p.warna as MaterialColor;

        return GestureDetector(
          onTap: () => onChanged(p.nama),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin  : const EdgeInsets.only(bottom: 10),
            padding : const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: pilih ? warna.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pilih ? warna.shade600 : Colors.grey.shade300,
                width: pilih ? 1.8 : 1,
              ),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  pilih ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: pilih ? warna.shade700 : Colors.grey,
                  size : 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                          color: warna.shade600, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(p.nama,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14,
                            color: pilih ? warna.shade900 : Colors.black87)),
                    const SizedBox(width: 6),
                    Text('(${p.subjudul})',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade700)),
                  ]),
                  const SizedBox(height: 4),
                  Text(p.keterangan,
                      style: const TextStyle(fontSize: 12, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(p.alur,
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: warna.shade800)),
                  const SizedBox(height: 2),
                  Text(
                    p.catatanWajib
                        ? 'Catatan wajib diisi.'
                        : 'Catatan opsional.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ]),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }
}
