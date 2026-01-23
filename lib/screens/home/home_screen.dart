import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/calorie_summary_card.dart';
import 'widgets/scan_button.dart';
import 'widgets/mood_card.dart';
import 'widgets/food_diary_section.dart';

import '../../providers/user_provider.dart';
import '../diary/daily/daily_screen.dart';

import 'package:foodbalance/widgets/slideUp_animation.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
        CircleAvatar(
          radius: 25,
          backgroundImage: photoUrl != null
              ? NetworkImage(photoUrl!)
              : const AssetImage("assets/images/profile.png") as ImageProvider,
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
