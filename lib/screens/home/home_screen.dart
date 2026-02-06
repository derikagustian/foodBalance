import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/calorie_summary_card.dart';
import 'widgets/scan_button.dart';
import 'widgets/mood_card.dart';
import 'widgets/food_diary_section.dart';

import '../../providers/user_provider.dart';
import '../diary/daily/daily_screen.dart';

import 'package:foodbalance/screens/scan/ai_scan_screen.dart';

import 'package:foodbalance/widgets/slideUp_animation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();

    final userProv = Provider.of<UserProvider>(context, listen: false);

    userProv.onGoalReached = () {
      if (!_isDialogShowing) {
        _showCelebrationDialog();
      }
    };

    Future.microtask(() => userProv.loadData());
  }

  @override
  void dispose() {
    final userProv = Provider.of<UserProvider>(context, listen: false);
    userProv.onGoalReached = null;
    super.dispose();
  }

  void _showCelebrationDialog() {
    // 3. Set flag ke true saat dialog muncul
    setState(() {
      _isDialogShowing = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/success.json',
              width: 250,
              height: 250,
              repeat: false,
            ),
            const Text(
              "Goal Tercapai! 🎉",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Energi harianmu sudah terpenuhi. Pertahankan pola makan sehatmu ya!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  // 4. Set flag kembali ke false saat dialog ditutup
                  setState(() {
                    _isDialogShowing = false;
                  });
                  Navigator.pop(context);
                },
                child: const Text(
                  "Luar Biasa!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final user = FirebaseAuth.instance.currentUser;

    final tanggalFormatted = DateFormat(
      'EEEE, d MMMM',
      'id_ID',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7C3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(tanggal: tanggalFormatted, photoUrl: user?.photoURL),

              const SizedBox(height: 20),

              if (userProv.pendingFood != null) ...[
                EntranceFaded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.orange,
                        ), // Ikon AI
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Hasil Scan AI Belum Disimpan",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                "${(userProv.pendingFood!['items'] as List).length} item makanan terdeteksi",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final draft = userProv.pendingFood!;

                            AiScanPage.showResultSheet(
                              context: context,
                              items: List<Map<String, dynamic>>.from(
                                draft['items'],
                              ),
                              scanTime: draft['scanTime'],
                            );
                          },
                          child: const Text("Detail"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => userProv.clearPendingFood(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              EntranceFaded(
                delay: const Duration(milliseconds: 200),
                child: CalorieSummaryCard(
                  targetCalories: userProv.targetKaloriHarian,
                  consumedCalories: userProv.totalConsumedCalories,
                  carbs: userProv.totalConsumedCarbs,
                  protein: userProv.totalConsumedProtein,
                  fat: userProv.totalConsumedFat,
                ),
              ),

              if (userProv.totalConsumedCalories >=
                      userProv.targetKaloriHarian &&
                  userProv.targetKaloriHarian > 0)
                EntranceFaded(
                  delay: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: _OverLimitMessage(),
                  ),
                ),

              const SizedBox(height: 20),

              EntranceFaded(
                delay: const Duration(milliseconds: 400),
                child: const ScanButtonsSection(),
              ),

              const SizedBox(height: 20),

              EntranceFaded(
                delay: const Duration(milliseconds: 600),
                child: MoodCard(provider: userProv),
              ),

              const SizedBox(height: 25),

              EntranceFaded(
                delay: const Duration(milliseconds: 800),
                child: _DiaryHeader(
                  onViewAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyLogPage()),
                  ),
                ),
              ),

              EntranceFaded(
                delay: const Duration(milliseconds: 1000),
                child: FoodDiarySection(provider: userProv),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String tanggal;
  final String? photoUrl;

  const _Header({required this.tanggal, required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hallo",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(tanggal, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ],
    );
  }
}

class _DiaryHeader extends StatelessWidget {
  final VoidCallback onViewAll;

  const _DiaryHeader({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Makanan Hari ini",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(onPressed: onViewAll, child: const Text("Lihat semua")),
      ],
    );
  }
}

class _OverLimitMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Menggunakan warna putih/cream lembut agar kontras dengan BG kuning
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Energi luar biasa!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Konsumsi kalorimu sedikit melebihi target hari ini, tapi jangan khawatir. Tubuhmu tetap butuh energi, yuk seimbangkan lagi besok ya! ✨",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
