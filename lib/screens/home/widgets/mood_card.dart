import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodbalance/providers/user_provider.dart';

/* =====================================================
   MOOD CARD
===================================================== */

class MoodCard extends StatelessWidget {
  final UserProvider provider;

  const MoodCard({super.key, required this.provider});

  static const List<String> _moods = ["😍", "🤗", "😊", "😔", "☹️"];

  @override
  Widget build(BuildContext context) {
    final Map<String, GlobalKey> emojiKeys = {
      for (var emoji in _moods) emoji: GlobalKey(),
    };

    void checkHover(Offset position) {
      for (final emoji in _moods) {
        final RenderBox? box =
            emojiKeys[emoji]?.currentContext?.findRenderObject() as RenderBox?;

        if (box == null) continue;

        final Offset local = box.globalToLocal(position);
        if (box.size.contains(local)) {
          if (provider.hoveredMood != emoji) {
            provider.setHoveredMood(emoji);
            HapticFeedback.selectionClick();
          }
          return;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Text(
            "Bagaimana Mood Anda Hari Ini?",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),

          /// EMOJI SELECTOR
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (d) => checkHover(d.globalPosition),
            onPanUpdate: (d) => checkHover(d.globalPosition),
            onPanEnd: (_) {
              if (provider.hoveredMood.isNotEmpty) {
                provider.updateMood(provider.hoveredMood);
              }
              provider.setHoveredMood("");
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _moods.map((emoji) {
                final bool isHovered = provider.hoveredMood == emoji;
                final bool isSelected = provider.selectedMood == emoji;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      provider.setHoveredMood("");
                      provider.updateMood(emoji);
                    },
                    child: Center(
                      child: AnimatedScale(
                        key: emojiKeys[emoji],
                        scale: isHovered
                            ? 1.4
                            : isSelected
                            ? 1.2
                            : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
