import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/auth_service.dart';
import 'package:inventori_bank/pages/user/user_main_page.dart';
import 'package:inventori_bank/pages/pimpinan/pimpinan_main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _hidePass  = true;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_usernameCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.trim().isEmpty) {
      _snack('Username dan password wajib diisi.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final result = await AuthService.login(
        _usernameCtrl.text.trim(), _passwordCtrl.text.trim());
    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success'] == true) {
      final roleId = result['data']['role_id'];
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => roleId == AppConstants.rolePimpinan
            ? const PimpinanMainPage()
            : const UserMainPage(),
      ));
    } else {
      _snack(result['message'] ?? 'Login gagal.', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior       : SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(AppConstants.primaryColor);

    return Scaffold(
      backgroundColor: const Color(AppConstants.bgColor),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(children: [

            const SizedBox(height: 24),

            // Logo
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.inventory_2,
                  size: 44, color: Colors.white),
            ),

            const SizedBox(height: 16),
            const Text('Inventori Bank',
                style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColor))),
            const Text('PT. Bank XYZ',
                style: TextStyle(color: Colors.grey, fontSize: 13)),

            const SizedBox(height: 40),

            // Form Card
            Container(
              padding   : const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 15)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text('Masuk ke Akun',
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Gunakan akun yang diberikan Administrator',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),

                  const SizedBox(height: 20),

                  // Username
                  TextField(
                    controller  : _usernameCtrl,
                    decoration  : InputDecoration(
                      labelText : 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border    : OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide  : const BorderSide(
                            color: primary, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller : _passwordCtrl,
                    obscureText: _hidePass,
                    decoration : InputDecoration(
                      labelText : 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_hidePass
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _hidePass = !_hidePass),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide  : const BorderSide(
                            color: primary, width: 2),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),

                  const SizedBox(height: 24),

                  // Tombol Login
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child    : _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text('Login',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text('© 2025 PT Bank XYZ',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}