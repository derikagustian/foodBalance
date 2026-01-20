import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodbalance/screens/AiScan_screen.dart';
import 'package:foodbalance/screens/barcodeScan_screen.dart';
import 'package:foodbalance/providers/user_provider.dart';
import 'package:foodbalance/screens/daily_screen.dart';
import 'package:foodbalance/widgets/slideUp_animation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime sekarang = DateTime.now();
    String tanggalFormatted = DateFormat(
      'EEEE, d MMMM',
      'id_ID',
    ).format(sekarang);

    final userProv = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7C3),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER DENGAN PROFIL ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Hallo",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            tanggalFormatted,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          print("Profile Clicked");
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                            image: const DecorationImage(
                              image: AssetImage("assets/images/profile.png"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  EntranceFaded(
                    delay: const Duration(milliseconds: 200),
                    child: _buildMainCard(
                      userProv.targetKaloriHarian,
                      userProv.totalConsumedCalories,
                      userProv.totalConsumedCarbs,
                      userProv.totalConsumedProtein,
                      userProv.totalConsumedFat,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tombol Scan
                  // TweenAnimationBuilder<double>(
                  //   tween: Tween(begin: 0.0, end: 1.0),
                  //   duration: const Duration(milliseconds: 800),
                  //   curve: Curves.easeOutBack,
                  //   builder: (context, value, child) {
                  //     return Transform.scale(scale: value, child: child);
                  //   },
                  //   child: _buildScanButton(
                  //     text: "Scan Makanan dengan AI",
                  //     icon: Icons.auto_awesome,
                  //     color: const Color(0xFF2E7D32),
                  //     textColor: Colors.white,
                  //     onTap: () => Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const AiScanPage(),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 10),
                  // TweenAnimationBuilder<double>(
                  //   tween: Tween(begin: 0.0, end: 1.0),
                  //   duration: const Duration(milliseconds: 800),
                  //   curve: Curves.easeOutBack,
                  //   builder: (context, value, child) {
                  //     return Transform.scale(scale: value, child: child);
                  //   },
                  //   child: _buildScanButton(
                  //     text: "Scan Barcode Produk",
                  //     icon: Icons.qr_code_scanner,
                  //     color: Colors.white,
                  //     textColor: Colors.black87,
                  //     onTap: () => Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (context) => const BarcodeScanPage(),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  EntranceFaded(
                    delay: const Duration(milliseconds: 400),
                    child: _buildScanButton(
                      text: "Scan Makanan dengan AI",
                      icon: Icons.auto_awesome,
                      color: const Color(0xFF2E7D32),
                      textColor: Colors.white,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AiScanPage(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  EntranceFaded(
                    delay: const Duration(milliseconds: 600),
                    child: _buildScanButton(
                      text: "Scan Barcode Produk",
                      icon: Icons.qr_code_scanner,
                      color: Colors.white,
                      textColor: Colors.black87,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BarcodeScanPage(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  EntranceFaded(
                    delay: const Duration(milliseconds: 800),
                    child: _buildMoodCard(userProv),
                  ),

                  const SizedBox(height: 20),

                  EntranceFaded(
                    delay: const Duration(milliseconds: 1000),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Makanan Hari ini",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DailyLogPage(),
                              ),
                            );
                          },
                          child: const Text("Lihat semua"),
                        ),
                      ],
                    ),
                  ),

                  _buildFoodDiarySection(userProv),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildMainCard(
    double target,
    double consumed,
    int carb,
    int prot,
    int fat,
  ) {
    double remaining = target - consumed;
    if (remaining < 0) remaining = 0;

    int targetKarbo = ((target * 0.5) / 4).toInt();
    int targetProtein = ((target * 0.2) / 4).toInt();
    int targetLemak = ((target * 0.3) / 9).toInt();

    final animationKey = ValueKey(target);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // --- ANIMASI LINGKARAN ---
                SizedBox(
                  width: 100,
                  height: 100,
                  child: TweenAnimationBuilder<double>(
                    key: animationKey,
                    tween: Tween<double>(
                      begin: 0.0,
                      end: (target > 0)
                          ? (remaining / target).clamp(0.0, 1.0)
                          : 0.0,
                    ),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeInOutCubic,
                    builder: (context, animValue, child) {
                      return CircularProgressIndicator(
                        value: animValue,
                        strokeWidth: 10,
                        color: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        strokeCap: StrokeCap.round,
                      );
                    },
                  ),
                ),
                // --- ANIMASI TEKS ANGKA ---
                TweenAnimationBuilder<double>(
                  key: animationKey,
                  tween: Tween<double>(begin: 0.0, end: remaining),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOutCubic,
                  builder: (context, value, child) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${value.toInt()}",
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
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _macroRow(
                  "KARBO",
                  "${targetKarbo > 0 ? ((carb / targetKarbo) * 100).toInt() : 0}%",
                  "$carb/${targetKarbo}g",
                  carb.toDouble(),
                  targetKarbo.toDouble(),
                ),
                const SizedBox(height: 15),
                _macroRow(
                  "PROTEIN",
                  "${targetProtein > 0 ? ((prot / targetProtein) * 100).toInt() : 0}%",
                  "$prot/${targetProtein}g",
                  prot.toDouble(),
                  targetProtein.toDouble(),
                ),
                const SizedBox(height: 15),
                _macroRow(
                  "LEMAK",
                  "${targetLemak > 0 ? ((fat / targetLemak) * 100).toInt() : 0}%",
                  "$fat/${targetLemak}g",
                  fat.toDouble(),
                  targetLemak.toDouble(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodDiarySection(UserProvider prov) {
    if (prov.foodDiary.isEmpty) {
      return EntranceFaded(
        key: const ValueKey('empty_state_card'),
        delay: const Duration(milliseconds: 1200),
        child: _buildEmptyFoodCard(),
      );
    }

    return Column(
      children: List.generate(prov.foodDiary.length, (index) {
        final item = prov.foodDiary[index];
        // Gunakan prefix 'food_' agar ID database tidak bentrok dengan ID lain
        return _AnimatedFoodCard(
          key: ValueKey('food_${item['id']}'),
          item: item,
          prov: prov,
          index: index,
        );
      }),
    );
  }
}

// --- WIDGET KOMPONEN LAIN ---

Widget _buildScanButton({
  required String text,
  required IconData icon,
  required Color color,
  required Color textColor,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _macroRow(
  String label,
  String percent,
  String gram,
  double currentValue,
  double targetValue,
) {
  double progress = (targetValue > 0)
      ? (currentValue / targetValue).clamp(0.0, 1.0)
      : 0.0;

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
                gram,
                style: const TextStyle(color: Colors.white70, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 6),
      // --- PROGRESS BAR ANIMASI ---
      Stack(
        children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              return FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ],
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

//mood card
Widget _buildMoodCard(UserProvider prov) {
  List<String> moods = ["😍", "🤗", "😊", "😔", "☹️"];

  final Map<String, GlobalKey> emojiKeys = {
    for (var emoji in moods) emoji: GlobalKey(),
  };

  void checkStatus(Offset position) {
    for (var emoji in moods) {
      final RenderBox? box =
          emojiKeys[emoji]?.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        final Offset localPosition = box.globalToLocal(position);
        if (box.size.contains(localPosition)) {
          if (prov.hoveredMood != emoji) {
            prov.setHoveredMood(emoji);
            HapticFeedback.selectionClick();
          }
          return;
        }
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
        GestureDetector(
          onPanDown: (details) => checkStatus(details.globalPosition),
          onPanUpdate: (details) => checkStatus(details.globalPosition),
          onPanEnd: (_) {
            if (prov.hoveredMood.isNotEmpty) {
              prov.updateMood(prov.hoveredMood);
            }
            prov.setHoveredMood("");
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((emoji) {
              bool isHovered = prov.hoveredMood == emoji;
              bool isSelected = prov.selectedMood == emoji;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    prov.setHoveredMood("");
                    prov.updateMood(emoji);
                  },
                  child: Center(
                    child: AnimatedScale(
                      key: emojiKeys[emoji],
                      scale: isHovered ? 1.4 : (isSelected ? 1.2 : 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      child: Text(emoji, style: const TextStyle(fontSize: 25)),
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

Widget _buildEmptyFoodCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: const Color(0xFF2E7D32).withOpacity(0.8),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Column(
      children: const [
        Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 40),
        SizedBox(height: 10),
        Text(
          "Belum ada makanan tercatat hari ini",
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}

// animasi list makanan
class _AnimatedFoodCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final UserProvider prov;
  final int index;

  const _AnimatedFoodCard({
    super.key,
    required this.item,
    required this.prov,
    required this.index,
  });

  @override
  State<_AnimatedFoodCard> createState() => _AnimatedFoodCardState();
}

class _AnimatedFoodCardState extends State<_AnimatedFoodCard> {
  bool _isVisible = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    Future.delayed(Duration(milliseconds: 1200 + (widget.index * 150)), () {
      if (mounted) {
        setState(() {
          _isReady = true;
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      // Tambahkan index ke dalam key agar Flutter merender ulang jika urutan berubah
      key: widget.key ?? ValueKey('card_${widget.item['id']}_${widget.index}'),
      onVisibilityChanged: (info) {
        // Jika sedang transisi halaman, info.visibleFraction mungkin 1.0 tapi
        // kita ingin memastikan animasi tetap merespon.
        if (!_isReady) return;

        if (info.visibleFraction > 0.1) {
          if (mounted && !_isVisible) {
            setState(() => _isVisible = true);
          }
        } else if (info.visibleFraction <= 0.05) {
          // Gunakan threshold kecil daripada 0 pas
          if (mounted && _isVisible) {
            setState(() => _isVisible = false);
          }
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 500),
        opacity: _isVisible ? 1.0 : 0.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isVisible ? 0 : 20, 0),
          margin: const EdgeInsets.only(bottom: 10),
          child: _buildItemContent(),
        ),
      ),
    );
  }

  Widget _buildItemContent() {
    return Dismissible(
      key: widget.key!,
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.prov.deleteFood(widget.item['id']),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
          ],
        ),
        child: ListTile(
          isThreeLine:
              true, // Tambahkan ini agar layout lebih rapi untuk 3 baris
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF2E7D32),
            child: Icon(Icons.restaurant, color: Colors.white, size: 18),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              // --- PENAMBAHAN CATEGORY ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(top: 2, bottom: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.item['category'].toString().toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            "${widget.item['carb']}g Karbo • ${widget.item['protein']}g Protein",
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            "+${widget.item['calories']} kkal",
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// slide hallo dan motivasi
// class RollingHeader extends StatefulWidget {
//   final String userName;
//   const RollingHeader({super.key, required this.userName});

//   @override
//   State<RollingHeader> createState() => _RollingHeaderState();
// }

// class _RollingHeaderState extends State<RollingHeader> {
//   int _index = 0;
//   late List<String> _phrases;

//   @override
//   void initState() {
//     super.initState();
//     _phrases = [
//       "Hallo, ${widget.userName}!",
//       "Sudah makan sehat hari ini?",
//       "Semangat capai target kalori!",
//       "Jangan lupa minum air putih!",
//       "Tubuh sehat, jiwa kuat! 💪",
//     ];
//     _startTimer();
//   }

//   void _startTimer() async {
//     while (mounted) {
//       await Future.delayed(const Duration(seconds: 4));
//       if (mounted) {
//         setState(() {
//           _index = (_index + 1) % _phrases.length;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 600),
//       transitionBuilder: (Widget child, Animation<double> animation) {
//         // Animasi Masuk: Dari Kiri (Offset -1) ke Tengah (Offset 0)
//         final inAnimation =
//             Tween<Offset>(
//               begin: const Offset(-1.2, 0),
//               end: Offset.zero,
//             ).animate(
//               CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
//             );

//         // Animasi Keluar: Dari Tengah (Offset 0) ke Kiri (Offset -1)
//         // Agar terlihat "terdorong" keluar ke arah yang sama saat masuk
//         final outAnimation =
//             Tween<Offset>(
//               begin: const Offset(-1.2, 0),
//               end: Offset.zero,
//             ).animate(
//               CurvedAnimation(parent: animation, curve: Curves.easeInCubic),
//             );

//         return ClipRect(
//           // Memotong agar teks tidak terlihat di luar margin
//           child: SlideTransition(
//             position: child.key == ValueKey(_index)
//                 ? inAnimation
//                 : outAnimation,
//             child: FadeTransition(opacity: animation, child: child),
//           ),
//         );
//       },
//       child: Text(
//         _phrases[_index],
//         key: ValueKey(_index),
//         style: const TextStyle(
//           fontSize: 24, // Sedikit lebih kecil agar teks panjang tidak terpotong
//           fontWeight: FontWeight.bold,
//           color: Colors.black,
//         ),
//       ),
//     );
//   }
// }
