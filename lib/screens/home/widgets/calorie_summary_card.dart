import 'package:flutter/material.dart';

class CalorieSummaryCard extends StatelessWidget {
  final double targetCalories;
  final double consumedCalories;
  final int carbs;
  final int protein;
  final int fat;

  const CalorieSummaryCard({
    super.key,
    required this.targetCalories,
    required this.consumedCalories,
    required this.carbs,
    required this.protein,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final double remainingCalories = (targetCalories - consumedCalories).clamp(
      0,
      targetCalories,
    );

    final int targetCarbs = ((targetCalories * 0.5) / 4).toInt();
    final int targetProtein = ((targetCalories * 0.2) / 4).toInt();
    final int targetFat = ((targetCalories * 0.3) / 9).toInt();

    final animationKey = ValueKey(targetCalories);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _CalorieCircle(
            remaining: remainingCalories,
            target: targetCalories,
            animationKey: animationKey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MacroRow(label: "KARBO", current: carbs, target: targetCarbs),
                const SizedBox(height: 15),
                _MacroRow(
                  label: "PROTEIN",
                  current: protein,
                  target: targetProtein,
                ),
                const SizedBox(height: 15),
                _MacroRow(label: "LEMAK", current: fat, target: targetFat),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =======================
   CIRCLE CALORIE WIDGET
======================= */

class _CalorieCircle extends StatelessWidget {
  final double remaining;
  final double target;
  final Key animationKey;

  const _CalorieCircle({
    required this.remaining,
    required this.target,
    required this.animationKey,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (remaining / target).clamp(0.0, 1.0) : 0.0;

    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: TweenAnimationBuilder<double>(
              key: animationKey,
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOutCubic,
              builder: (_, value, __) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 10,
                  color: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
          TweenAnimationBuilder<double>(
            key: animationKey,
            tween: Tween<double>(begin: 0, end: remaining),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOutCubic,
            builder: (_, value, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Sisa kkal",
                    style: TextStyle(color: Colors.white70, fontSize: 8),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/* =======================
      MACRO ROW
======================= */

class _MacroRow extends StatelessWidget {
  final String label;
  final int current;
  final int target;

  const _MacroRow({
    required this.label,
    required this.current,
    required this.target,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = target > 0
        ? (current / target).clamp(0.0, 1.0)
        : 0.0;

    final String percent = target > 0
        ? "${((current / target) * 100).toInt()}%"
        : "0%";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  percent,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                Text(
                  "$current/$target g",
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOutCubic,
              builder: (_, value, __) {
                return FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
