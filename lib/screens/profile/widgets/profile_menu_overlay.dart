import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodbalance/screens/diary/daily/daily_screen.dart';
import 'package:foodbalance/services/firebase_service.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'package:foodbalance/providers/user_provider.dart';
import 'package:foodbalance/services/notification_service.dart';

class ProfileMenuOverlay extends StatefulWidget {
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
  State<ProfileMenuOverlay> createState() => _ProfileMenuOverlayState();
}

class _ProfileMenuOverlayState extends State<ProfileMenuOverlay> {
  bool _isSettingsExpanded = false;
  bool _isBackingUp = false;
  bool _isReminderActive = false; // Status awal pengingat

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final size = MediaQuery.of(context).size;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: size.width * 0.75,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
          ),
          child: Column(
            children: [
              _buildHeader(user),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ListView(
                      padding: const EdgeInsets.only(
                        left: 10,
                        top: 15,
                        right: 10,
                      ),
                      children: [
                        _buildMenuItem(
                          Icons.link,
                          "Tautkan Akun",
                          onTap: () => _handleAccountLinking(user),
                        ),
                        _buildMenuItem(
                          Icons.history,
                          "Riwayat Makan",
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DailyLogPage(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          Icons.notifications_active_outlined,
                          "Pengingat Makan",
                          trailing: Switch(
                            value: _isReminderActive,
                            activeColor: const Color(0xFF2E7D32),
                            onChanged: (bool value) {
                              _toggleReminders(value);
                            },
                          ),
                          onTap: () {
                            _toggleReminders(!_isReminderActive);
                          },
                        ),
                        _buildExpandableSettings(),
                        const Divider(height: 30, indent: 20, endIndent: 20),
                        _buildMenuItem(
                          Icons.logout,
                          "Keluar",
                          isDanger: true,
                          onTap: () => _handleLogoutSelection(user),
                        ),
                      ],
                    ),
                    _buildAvatarOverlay(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildHeader(User? user) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(left: 95, bottom: 25, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.displayName ??
                user?.displayName ??
                (user?.isAnonymous == true ? "User Tamu" : "Pengguna"),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.email ?? user?.email ?? "Data belum tersinkron",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarOverlay() {
    return Positioned(
      left: 20,
      top: -80,
      child: Hero(
        tag: 'profilePic',
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[200],
            backgroundImage: (widget.photoUrl != null)
                ? NetworkImage(widget.photoUrl!)
                : const AssetImage("assets/images/profile.png")
                      as ImageProvider,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSettings() {
    return Column(
      children: [
        _buildMenuItem(
          Icons.settings_outlined,
          "Pengaturan",
          trailing: Icon(
            _isSettingsExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.grey,
          ),
          onTap: () =>
              setState(() => _isSettingsExpanded = !_isSettingsExpanded),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isSettingsExpanded
              ? Container(
                  margin: const EdgeInsets.fromLTRB(30, 0, 15, 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildSubMenuItem(
                        Icons.delete_sweep_outlined,
                        "Auto Cleanup Data",
                        isDanger: true,
                        onTap: () => _showCleanupOptions(),
                      ),
                      _buildSubMenuItem(
                        Icons.cloud_sync_outlined,
                        "Cadangkan & Sinkronisasi",
                        onTap: () =>
                            _showBackupOptions(), // Panggil dialog baru
                      ),
                      _buildSubMenuItem(
                        Icons.person_remove_outlined,
                        "Hapus Akun Selamanya",
                        isDanger: true,
                        onTap: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user?.isAnonymous ?? true) {
                            _performLogout();
                          } else {
                            _showDeleteAccountDialog(context);
                          }
                        },
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    bool isDanger = false,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isDanger ? Colors.red : Colors.grey[700],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? Colors.red : Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: trailing,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildSubMenuItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
    bool isDanger = false,
  }) {
    return ListTile(
      onTap: onTap,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        icon,
        size: 18,
        color: isDanger ? Colors.red[300] : Colors.green[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          color: isDanger ? Colors.red : Colors.black87,
        ),
      ),
    );
  }

  // --- LOGIC & ACTIONS ---

  void _runBackupTask() async {
    if (_isBackingUp) return;

    setState(() => _isBackingUp = true);

    try {
      final provider = context.read<UserProvider>();

      await provider.runFullBackup();

      if (mounted) {
        _showSnackBar("Data berhasil dicadangkan ke Cloud! 🚀");
      }
    } catch (e) {
      if (mounted) _showSnackBar("Gagal mencadangkan: $e");
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  void _handleAccountLinking(User? user) {
    if (user?.isAnonymous ?? false) {
      _linkWithGoogle();
    } else {
      _showSnackBar("Akun Anda sudah terhubung.");
    }
  }

  void _handleLogoutSelection(User? user) {
    if (user?.isAnonymous ?? false) {
      _showActionDialog(
        title: "Peringatan Akun Tamu",
        content:
            "Data Anda akan hilang jika keluar sekarang. Hubungkan ke Google untuk simpan permanen?",
        confirmLabel: "Tautkan Google",
        onConfirm: _linkWithGoogle,
        cancelLabel: "Hapus & Keluar",
        onCancel: () => _performLogout(),
        isCritical: true,
      );
    } else {
      _showActionDialog(
        title: "Keluar",
        content: "Apakah Anda yakin ingin keluar?",
        onConfirm: _performLogout,
      );
    }
  }

  void _showActionDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmLabel = "Ya",
    String cancelLabel = "Batal",
    VoidCallback? onCancel,
    bool isCritical = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: onCancel ?? () => Navigator.pop(ctx),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCritical
                  ? Colors.red
                  : const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isAnonymous = user?.isAnonymous ?? true;
    final TextEditingController passwordController = TextEditingController();
    final firebaseService = FirebaseService();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                isAnonymous ? "Hapus Sesi Tamu?" : "Hapus Akun Permanen",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAnonymous
                        ? "Semua data yang Anda catat sebagai tamu akan dihapus permanen dari cloud."
                        : "Tindakan ini tidak dapat dibatalkan. Masukkan kata sandi Anda untuk menghapus akun dan seluruh data Cloud.",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  if (!isAnonymous) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Kata Sandi",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          try {
                            if (!isAnonymous) {
                              await firebaseService.reauthenticateAndDelete(
                                passwordController.text,
                              );
                            } else {
                              await firebaseService.deleteUserCloudData();
                              await user?.delete();
                            }

                            await userProvider.clearAllData();

                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (r) => false,
                              );
                              _showSnackBar("Akun berhasil dihapus.");
                            }
                          } catch (e) {
                            setState(() => isLoading = false);
                            if (context.mounted) {
                              _showSnackBar(
                                "Gagal: Pastikan kata sandi benar.",
                              );
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Hapus Selamanya"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performLogout() async {
    final provider = context.read<UserProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final firebaseService = FirebaseService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await NotificationService().cancelAllNotifications();
      if (user != null && user.isAnonymous) {
        await firebaseService.deleteUserCloudData();
        await provider.clearAllData();
      } else {
        await FirebaseAuth.instance.signOut();
        await google_auth.GoogleSignIn().signOut();
      }

      if (mounted) {
        Navigator.pop(context);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar("Gagal logout: $e");
      }
    }
  }

  Future<void> _linkWithGoogle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final googleUser = await google_auth.GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.linkWithCredential(credential);

      final provider = context.read<UserProvider>();

      await provider.kalkulasiDanSimpan(
        bb: provider.berat,
        tb: provider.tinggi,
        age: provider.usia,
        jk: provider.jenisKelamin,
        goal: provider.tujuan,
      );

      if (mounted) {
        _showSnackBar("Akun berhasil ditautkan ke Google! 🎉");
        setState(() {});
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        _showSnackBar("Email ini sudah terhubung dengan akun lain.");
      } else {
        _showSnackBar("Gagal menautkan: ${e.message}");
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // --- LOGIKA BACKUP ---
  void _showCleanupOptions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Colors.green),
            SizedBox(width: 10),
            Text("Auto Cleanup", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          "Pilih batas usia data lokal yang akan tetap disimpan di HP. Data yang lebih lama akan dihapus (tetap aman di Cloud).",
          style: TextStyle(fontSize: 13),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogOption(ctx, "30 Hari Terakhir", 30),
              _buildDialogOption(ctx, "90 Hari Terakhir", 90),
              _buildDialogOption(ctx, "180 Hari Terakhir", 180),
              const Divider(),
              _buildDialogOption(ctx, "Hapus Semua (Reset)", 0, isDanger: true),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDialogOption(
    BuildContext ctx,
    String label,
    int days, {
    bool isDanger = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
        onPressed: () async {
          final navigator = Navigator.of(ctx);
          final userProvider = context.read<UserProvider>();

          navigator.pop();

          try {
            await userProvider.setAutoCleanupDays(days);

            if (mounted) {
              _showSnackBar(
                isDanger
                    ? "Data lokal berhasil di-reset sepenuhnya."
                    : "Auto Cleanup aktif: Data lebih dari $label akan dihapus rutin.",
              );
            }
          } catch (e) {
            if (mounted) {
              _showSnackBar("Gagal membersihkan data: $e");
            }
          }
        },
        child: Text(
          label,
          style: TextStyle(
            color: isDanger ? Colors.red : Colors.black87,
            fontWeight: isDanger ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showBackupOptions() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final userProvider = context.watch<UserProvider>();
          final int currentInterval = userProvider.backupInterval;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Pencadangan Data",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _isBackingUp
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload, color: Colors.blue),
                  title: const Text(
                    "Cadangkan Sekarang",
                    style: TextStyle(fontSize: 14),
                  ),
                  onTap: _isBackingUp
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _runBackupTask();
                        },
                ),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  "Interval Backup Otomatis",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: [7, 30, 90].contains(currentInterval)
                          ? currentInterval
                          : 7,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 7,
                          child: Text("Setiap 7 Hari"),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text("Setiap 30 Hari"),
                        ),
                        DropdownMenuItem(
                          value: 90,
                          child: Text("Setiap 90 Hari"),
                        ),
                      ],
                      onChanged: (value) async {
                        if (value != null) {
                          await context.read<UserProvider>().setBackupInterval(
                            value,
                          );
                          setDialogState(() {});
                          _showSnackBar("Backup otomatis diatur: $value hari");
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tutup"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleReminders(bool value) async {
    setState(() {
      _isReminderActive = value;
    });

    final notificationService = NotificationService();

    if (value) {
      // Jika dinyalakan (On)
      await notificationService.initNotification();

      await notificationService.scheduleDailyNotification(
        id: 1,
        title: "Waktunya Sarapan! 🥣",
        body: "Ayo catat sarapanmu.",
        hour: 7,
        minute: 30,
      );
      await notificationService.scheduleDailyNotification(
        id: 2,
        title: "Makan Siang 🍱",
        body: "Jangan lupa isi energimu siang ini.",
        hour: 12,
        minute: 30,
      );
      await notificationService.scheduleDailyNotification(
        id: 3,
        title: "Makan Malam 🥗",
        body: "Waktunya makan malam ringan.",
        hour: 19,
        minute: 0,
      );

      _showSnackBar("Pengingat makan otomatis aktif! 🔔");
    } else {
      // Jika dimatikan (Off)
      await notificationService.cancelAllNotifications();
      _showSnackBar("Pengingat makan dinonaktifkan. 🔕");
    }
  }
}
