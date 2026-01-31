import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:foodbalance/screens/auth/login_screen.dart';
import 'package:foodbalance/main.dart'; // Memastikan MainNavigation dikenali
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Map<String, String> selectedTip;

  final List<Map<String, String>> healthTips = [
    {
      "title": "Turun BB",
      "text":
          "Minum air putih sebelum makan dapat membantu mengontrol nafsu makan.",
    },
    {
      "title": "Jaga BB",
      "text": "Konsistensi adalah kunci. Tetap aktif bergerak setiap hari!",
    },
    {
      "title": "Naik BB",
      "text": "Fokus pada makanan padat nutrisi, bukan sekadar kalori kosong.",
    },
    {
      "title": "Fakta",
      "text":
          "Protein membutuhkan lebih banyak energi untuk dicerna dibandingkan lemak.",
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedTip = healthTips[Random().nextInt(healthTips.length)];

    _navigateToNext();
  }

  void _navigateToNext() async {
    FlutterNativeSplash.remove();

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    Widget nextScreen = FirebaseAuth.instance.currentUser == null
        ? const LoginPage()
        : const MainNavigation();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDF7C3), Color(0xFFFEFBEA)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/lottie/walking_avocado.json',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text(
                  selectedTip['title']!.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    letterSpacing: 2,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    selectedTip['text']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
