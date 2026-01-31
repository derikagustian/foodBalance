import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodbalance/providers/user_provider.dart';
import 'package:foodbalance/screens/auth/login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:path/path.dart'; // <--- Ini biasanya untuk file sistem, bisa dihapus jika tidak dipakai

class ProfileMenuOverlay extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final String? email;

  const ProfileMenuOverlay({
    super.key,
    this.photoUrl,
    this.displayName,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.75,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              bottomLeft: Radius.circular(30),
            ),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 30, top: 115),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName ?? "User",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          email ?? "user@email.com",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(left: 15, top: 20),
                      children: [
                        _buildMenuItem(
                          Icons.history,
                          "Riwayat Makan",
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          Icons.notifications_none,
                          "Notifikasi",
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          Icons.settings_outlined,
                          "Pengaturan",
                          onTap: () {},
                        ),
                        const Divider(),
                        _buildMenuItem(
                          Icons.logout,
                          "Keluar",
                          isDanger: true,
                          onTap: () async {
                            final user = FirebaseAuth.instance.currentUser;

                            // Jika user adalah Guest (Anonymous)
                            if (user != null && user.isAnonymous) {
                              _showUpgradeConfirmation(context);
                            } else {
                              // Jika user sudah Google Login, langsung tanya logout biasa
                              _showLogoutConfirm(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Posisi Avatar
              Positioned(
                left: 20,
                top: 50,
                child: Hero(
                  tag: 'profilePic',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundImage: (photoUrl != null)
                          ? NetworkImage(photoUrl!)
                          : const AssetImage("assets/images/profile.png")
                                as ImageProvider,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fungsi helper sekarang menerima parameter onTap
  Widget _buildMenuItem(
    IconData icon,
    String title, {
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors
          .transparent, // Menjaga latar belakang tetap putih dari Container utama
      child: InkWell(
        onTap: onTap,
        // Memberikan efek warna sedikit gelap saat ditekan
        splashColor: isDanger
            ? Colors.red.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        highlightColor: isDanger
            ? Colors.red.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        child: ListTile(
          // Menyamakan padding agar tetap konsisten dengan desain awal
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 2,
          ),
          leading: Icon(icon, color: isDanger ? Colors.red : Colors.grey[700]),
          title: Text(
            title,
            style: TextStyle(
              color: isDanger ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // 1. Dialog khusus User Guest
  void _showUpgradeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Simpan Data Anda?"),
        content: const Text(
          "Anda masuk sebagai Tamu. Jika keluar sekarang, semua data riwayat makan Anda akan dihapus selamanya. Hubungkan ke Google untuk menyimpan data?",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Tutup dialog
              _performLogout(context); // Panggil fungsi hapus semua & logout
            },
            child: const Text(
              "Hapus & Keluar",
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Panggil fungsi link account di sini nanti
              _handleLinkAccount(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text(
              "Hubungkan Google",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Dialog Logout Biasa (Untuk User Google)
  void _showLogoutConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => _performLogout(context),
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 3. Fungsi Eksekusi Logout (Sapu Bersih)
  Future<void> _performLogout(BuildContext context) async {
    try {
      await Provider.of<UserProvider>(context, listen: false).clearAllData();
      await FirebaseAuth.instance.signOut();
      await google_auth.GoogleSignIn().signOut();

      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint("Error logout: $e");
    }
  }

  Future<void> _handleLinkAccount(BuildContext context) async {
    try {
      final googleSignIn = google_auth.GoogleSignIn();
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) return; // User batal pilih akun

      final googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Proses Menautkan (Link)
      await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Akun berhasil ditautkan ke Google!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Gagal menautkan akun: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal menautkan: Akun Google mungkin sudah terpakai.",
            ),
          ),
        );
      }
    }
  }
}
