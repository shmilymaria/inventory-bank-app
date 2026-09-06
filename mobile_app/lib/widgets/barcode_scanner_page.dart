import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:inventori_bank/constants/app_constants.dart';

/// Halaman scanner barcode/QR yang dipakai bersama di semua fitur Admin
/// (Inbound, Checkout, Outbound, Audit/Stock Opname).
///
/// Cara pakai:
/// ```dart
/// final kode = await Navigator.push<String>(
///   context,
///   MaterialPageRoute(builder: (_) => const BarcodeScannerPage(
///     title: 'Scan Barang',
///   )),
/// );
/// if (kode != null) { ... }
/// ```
class BarcodeScannerPage extends StatefulWidget {
  final String title;
  final String subtitle;

  const BarcodeScannerPage({
    super.key,
    this.title    = 'Scan Barcode / QR',
    this.subtitle = 'Arahkan kamera ke barcode atau QR code',
  });

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _torchOn   = false;
  bool _sudahScan = false; // cegah double-pop saat beberapa frame terdeteksi bersamaan

  void _onDetect(BarcodeCapture capture) {
    if (_sudahScan) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final value = barcodes.first.rawValue;
    if (value == null || value.trim().isEmpty) return;

    _sudahScan = true;
    Navigator.pop(context, value.trim());
  }

  Future<void> _inputManual() async {
    final ctrl = TextEditingController();
    final hasil = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title  : const Text('Input Manual'),
        content: TextField(
          controller : ctrl,
          autofocus  : true,
          decoration : const InputDecoration(
            hintText: 'Ketik kode barang / kode QR...',
            border  : OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child    : const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child    : const Text('Cari'),
          ),
        ],
      ),
    );

    if (hasil != null && hasil.isNotEmpty && mounted) {
      Navigator.pop(context, hasil);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title          : Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation      : 0,
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect  : _onDetect,
            placeholderBuilder: (context, child) => Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Menyiapkan kamera...',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),

          // Overlay bingkai scan
          Center(
            child: Container(
              width : 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(AppConstants.primaryLightColor),
                    width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Subtitle & tombol input manual
          Positioned(
            left: 0, right: 0, bottom: 40,
            child: Column(children: [
              Container(
                margin : const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _inputManual,
                icon : const Icon(Icons.keyboard_outlined, color: Colors.white),
                label: const Text('Input Manual',
                    style: TextStyle(color: Colors.white)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}