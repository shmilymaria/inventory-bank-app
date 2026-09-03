import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'auth_service.dart';

class ApiService {

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type' : 'application/json',
      'Accept'       : 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
  try {
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    print('=== API GET: $url');
    
    final res = await http.get(
      url,
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
    
    print('=== STATUS: ${res.statusCode}');
    print('=== BODY: ${res.body}');
    
    return jsonDecode(res.body);
  } catch (e) {
    print('=== ERROR: $e');
    return {'success': false, 'message': 'Gagal terhubung ke server.'};
  }
}
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: await _headers(),
        body   : jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Gagal terhubung ke server.'};
    }
  }

  static Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final res = await http.patch(
        Uri.parse('${AppConstants.baseUrl}$endpoint'),
        headers: await _headers(),
        body   : jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Gagal terhubung ke server.'};
    }
  }
}