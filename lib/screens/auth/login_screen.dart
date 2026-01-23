import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'package:flutter/material.dart';
import 'package:foodbalance/main.dart'; // Pastikan path MainNavigation benar

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();

  static const Color darkGreen = Color(0xFF1B4D3E);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // 1. Fungsi Login Google
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final google_auth.GoogleSignIn googleSignIn = google_auth.GoogleSignIn();
      final google_auth.GoogleSignInAccount? googleUser = await googleSignIn
          .signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final google_auth.GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      _navigateToMain();
    } catch (e) {
      _showError("Google Login Gagal: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Fungsi Login Email (Simple)
  Future<void> _handleEmailLogin() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showError("Masukkan email yang valid");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Menggunakan password default karena UI kamu hanya minta email
      // Di Firebase, email login wajib pakai password
      await FirebaseAuth.instance
          .signInAnonymously(); // Sementara pakai anon agar tidak error password
      _navigateToMain();
    } catch (e) {
      _showError("Email Login Gagal: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. Fungsi Guest Login
  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      _navigateToMain();
    } catch (e) {
      _showError("Guest Login Gagal: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToMain() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkGreen,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Center(
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo/FB_logo.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.fastfood,
                              size: 100,
                              color: Colors.white,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Food Balance",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Create an account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enter your email to sign up for this app",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 30),

                  // Input Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "email@domain.com",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 15),

                  // Tombol Continue (Email)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleEmailLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Pemisah "or"
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.white38)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "or",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white38)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Social Buttons
                  _buildSocialButton(
                    context,
                    "Continue With Google",
                    "assets/icons/google.png",
                    Colors.white.withOpacity(0.3),
                    _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    context,
                    "Continue With Apple",
                    "assets/icons/apple.png",
                    Colors.white.withOpacity(0.3),
                    () => _showError("Fitur Apple Login belum diaktifkan"),
                  ),

                  const SizedBox(height: 20),

                  // Guest Login Link
                  TextButton(
                    onPressed: _isLoading ? null : _handleGuestLogin,
                    child: const Text(
                      "Masuk tanpa akun",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context,
    String text,
    String assetPath,
    Color color,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              assetPath,
              height: 22,
              width: 22,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.login, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
