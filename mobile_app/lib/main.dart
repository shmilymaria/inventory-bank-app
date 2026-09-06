import 'package:flutter/material.dart';
import 'package:inventori_bank/constants/app_constants.dart';
import 'package:inventori_bank/services/auth_service.dart';
import 'package:inventori_bank/pages/login_page.dart';
import 'package:inventori_bank/pages/user/user_main_page.dart';
import 'package:inventori_bank/pages/pimpinan/pimpinan_main_page.dart';
import 'package:inventori_bank/pages/admin/admin_main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventori Bank XYZ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppConstants.primaryColor),
          primary  : const Color(AppConstants.primaryColor),
        ),
        useMaterial3           : true,
        scaffoldBackgroundColor: const Color(AppConstants.bgColor),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(AppConstants.primaryColor),
          foregroundColor: Colors.white,
          elevation      : 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(AppConstants.primaryColor),
            foregroundColor: Colors.white,
            minimumSize    : const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ── Splash Screen ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      final roleId = await AuthService.getRoleId();
      if (!mounted) return;
      Widget target;
      if (roleId == AppConstants.roleAdmin) {
        target = const AdminMainPage();
      } else if (roleId == AppConstants.rolePimpinan) {
        target = const PimpinanMainPage();
      } else {
        target = const UserMainPage();
      }
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => target));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.primaryColor),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text('Inventori Bank',
                style: TextStyle(fontSize: 28,
                    fontWeight: FontWeight.bold, color: Colors.white)),
            Text('PT. Bank XYZ',
                style: TextStyle(fontSize: 14, color: Colors.white70)),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}