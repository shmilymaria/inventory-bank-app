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
}