import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/api_service.dart';

class AdminNotifikasiPage extends StatefulWidget {
  const AdminNotifikasiPage({super.key});
  @override
  State<AdminNotifikasiPage> createState() =>
      _AdminNotifikasiPageState();
}

class _AdminNotifikasiPageState extends State<AdminNotifikasiPage> {
  List<dynamic> _data    = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.get('/notifikasi');
    setState(() {
      _data    = res['data'] ?? [];
      _loading = false;
    });
  }

  Future<void> _bacaSemua() async {
    await ApiService.patch('/notifikasi/baca-semua', {});
    _load();
  }

  Future<void> _tandaiBaca(int id) async {
    await ApiService.patch('/notifikasi/$id/baca', {});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    const primary   = Color(AppConstants.primaryColor);
    final belumBaca = _data
        .where((n) => n['status_baca'] == 'Belum Dibaca')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Notifikasi${belumBaca > 0 ? " ($belumBaca)" : ""}'),
        backgroundColor: primary,
        automaticallyImplyLeading: false,
        actions: [
          if (belumBaca > 0)
            TextButton(
              onPressed: _bacaSemua,
              child    : const Text('Baca Semua',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color    : primary,
              child    : _data.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('Tidak ada notifikasi.',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding    : const EdgeInsets.all(12),
                      itemCount  : _data.length,
                      itemBuilder: (_, i) {
                        final n      = _data[i];
                        final dibaca = n['status_baca'] == 'Sudah Dibaca';

                        return GestureDetector(
                          onTap: () {
                            if (!dibaca) _tandaiBaca(n['id']);
                          },
                          child: Container(
                            margin    : const EdgeInsets.only(bottom: 10),
                            padding   : const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: dibaca
                                  ? Colors.white
                                  : const Color(AppConstants.primaryLightColor),
                              borderRadius: BorderRadius.circular(14),
                              border      : Border.all(
                                color: dibaca
                                    ? Colors.grey.shade200
                                    : const Color(AppConstants.primaryColor)
                                        .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding   : const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: dibaca
                                        ? Colors.grey.shade100
                                        : const Color(AppConstants.primaryColor)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    dibaca
                                        ? Icons.notifications_outlined
                                        : Icons.notifications_active,
                                    color: dibaca
                                        ? Colors.grey : primary,
                                    size : 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child: Text(
                                            n['judul'] ?? '',
                                            style: TextStyle(
                                              fontWeight: dibaca
                                                  ? FontWeight.normal
                                                  : FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        if (!dibaca)
                                          Container(
                                            width : 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(
                                                  AppConstants.primaryColor),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(
                                        n['pesan'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color  : Colors.grey),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(n['created_at'] ?? ''),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color  : Colors.grey.shade400),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/'
             '${dt.month.toString().padLeft(2, '0')}/'
             '${dt.year}  '
             '${dt.hour.toString().padLeft(2, '0')}:'
             '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}