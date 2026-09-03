import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventori_bank/constants/app_constants.dart';

class AuthService {

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept'      : 'application/json',
        },
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token',        data['data']['token']);
        await prefs.setInt   ('user_id',      data['data']['id']);
        await prefs.setString('nama_lengkap', data['data']['nama_lengkap']);
        await prefs.setString('username',     data['data']['username']);
        await prefs.setString('bagian',       data['data']['bagian'] ?? '');
        await prefs.setString('jabatan',      data['data']['jabatan'] ?? '');
        await prefs.setString('email',        data['data']['email'] ?? '');
        await prefs.setString('nomor_hp',     data['data']['nomor_hp'] ?? '');
        await prefs.setInt   ('role_id',      data['data']['role_id']);
        await prefs.setString('role_name',    data['data']['role_name']);
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server. Periksa koneksi jaringan.',
      };
    }
  }

  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('${AppConstants.baseUrl}/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept'       : 'application/json',
          },
        ).timeout(const Duration(seconds: 10));
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<int?> getRoleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('role_id');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id'     : prefs.getInt   ('user_id')      ?? 0,
      'nama_lengkap': prefs.getString('nama_lengkap') ?? '',
      'username'    : prefs.getString('username')     ?? '',
      'bagian'      : prefs.getString('bagian')       ?? '',
      'jabatan'     : prefs.getString('jabatan')      ?? '',
      'email'       : prefs.getString('email')        ?? '',
      'nomor_hp'    : prefs.getString('nomor_hp')     ?? '',
      'role_id'     : prefs.getInt   ('role_id')      ?? 0,
      'role_name'   : prefs.getString('role_name')    ?? '',
    };
  }
}