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
                    onTap: () async {
                      provider.setHoveredMood("");
                      provider.updateMood(emoji);

                      // Tampilkan loading dialog atau indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );

                      // Ambil saran dari AI
                      String recommendation = await provider
                          .getAiFoodRecommendation(emoji);

                      // Tutup loading
                      if (context.mounted) Navigator.pop(context);

                      // Tampilkan hasil AI dalam BottomSheet
                      if (context.mounted) {
                        _showAiSheet(context, emoji, recommendation);
                      }
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

  void _showAiSheet(BuildContext context, String emoji, String text) {
    // Kita coba pisahkan Nama Makanan dan Alasan jika AI mengikuti format
    // Jika tidak, kita tampilkan teks utuh dengan desain yang lebih baik.
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar (Indikator geser)
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),

            // Header Mood
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFE8F5E9),
              child: Text(emoji, style: const TextStyle(fontSize: 45)),
            ),
            const SizedBox(height: 15),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 18),
                SizedBox(width: 8),
                Text(
                  "REKOMENDASI NUTRISI AI",
                  style: TextStyle(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Area Teks dengan Scroll
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        color: Color(0xFF2E7D32),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                ),
                label: const Text(
                  "SAYA MENGERTI",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
