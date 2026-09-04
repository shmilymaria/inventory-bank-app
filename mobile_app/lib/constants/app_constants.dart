class AppConstants {
  // ── Base URL API Laravel ──────────────────────────────────
  // Gunakan 10.0.2.2 untuk Android Emulator (mengarah ke localhost PC)
  // Ganti dengan IP lokal PC (contoh: 192.168.1.5) untuk device fisik
  static const String baseUrl = 'http://192.168.18.16:8000/api';

  // ── Warna Tema (selaras dengan web admin #1565C0) ─────────
  static const int primaryColor     = 0xFF1565C0;
  static const int primaryDarkColor = 0xFF0D47A1;
  static const int primaryLightColor= 0xFFE3F2FD;
  static const int bgColor          = 0xFFF5F7FA;

  // ── Role ID ───────────────────────────────────────────────
  static const int roleAdmin    = 1;
  static const int roleStaff    = 2;
  static const int rolePimpinan = 3;

  // ── Host tanpa suffix "/api", dipakai untuk akses file storage ──
  // Contoh: baseUrl = http://192.168.18.16:8000/api
  //         baseHost = http://192.168.18.16:8000
  static String get baseHost =>
      baseUrl.endsWith('/api')
          ? baseUrl.substring(0, baseUrl.length - '/api'.length)
          : baseUrl;

  // ── Bangun URL gambar barang dari path yang dikirim API ──────
  // Menerima path relatif (contoh: "barang/kursi.jpg" atau
  // "/storage/barang/kursi.jpg") maupun URL absolut yang sudah lengkap.
  // Mengembalikan string kosong jika path kosong/null agar UI bisa
  // menampilkan placeholder.
  static String resolveImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    var clean = path.trim();
    if (clean.startsWith('/')) clean = clean.substring(1);
    if (!clean.startsWith('storage/')) clean = 'storage/$clean';
    return '$baseHost/$clean';
  }
}