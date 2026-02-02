import 'package:flutter/material.dart';
import 'package:foodbalance/providers/user_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

/* =====================================================
   FOOD DIARY SECTION
===================================================== */

class FoodDiarySection extends StatelessWidget {
  final UserProvider provider;
  const FoodDiarySection({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    // GANTI baris ini:
    final items = provider.todayFoodDiary; // Menggunakan getter hari ini

    if (items.isEmpty) {
      return const _EmptyFoodCard();
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return AnimatedFoodCard(
          key: ValueKey('food_${item['id']}'),
          item: item,
          provider: provider,
          index: index,
        );
      }),
    );
  }
}

/* =====================================================
   EMPTY STATE
===================================================== */

class _EmptyFoodCard extends StatelessWidget {
  const _EmptyFoodCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: const [
          Icon(
            Icons.local_fire_department,
            color: Colors.orangeAccent,
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            "Belum ada makanan tercatat hari ini",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

/* =====================================================
   ANIMATED FOOD CARD
===================================================== */

class AnimatedFoodCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final UserProvider provider;
  final int index;

  const AnimatedFoodCard({
    super.key,
    required this.item,
    required this.provider,
    required this.index,
  });

  @override
  State<AnimatedFoodCard> createState() => _AnimatedFoodCardState();
}

class _AnimatedFoodCardState extends State<AnimatedFoodCard> {
  bool _isVisible = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _startInitialAnimation();
  }

  void _startInitialAnimation() {
    Future.delayed(Duration(milliseconds: 1000 + widget.index * 150), () {
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
      key: widget.key ?? ValueKey('food_${widget.item['id']}_${widget.index}'),
      onVisibilityChanged: (info) {
        if (!_isReady) return;

        if (info.visibleFraction > 0.1 && !_isVisible) {
          setState(() => _isVisible = true);
        } else if (info.visibleFraction <= 0.05 && _isVisible) {
          setState(() => _isVisible = false);
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _isVisible ? 1 : 0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isVisible ? 0 : 20, 0),
          margin: const EdgeInsets.only(bottom: 10),
          child: _FoodCardContent(
            item: widget.item,
            onDelete: () => widget.provider.deleteFood(widget.item['id']),
          ),
        ),
      ),
    );
  }
}

/* =====================================================
   FOOD CARD CONTENT
===================================================== */

class _FoodCardContent extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const _FoodCardContent({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismiss_${item['id']}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
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
          isThreeLine: true,
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF2E7D32),
            child: Icon(Icons.restaurant, color: Colors.white, size: 18),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              _CategoryChip(category: item['category']),
            ],
          ),
          subtitle: Text(
            "${item['carb']}g Karbo • ${item['protein']}g Protein",
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            "+${item['calories']} kkal",
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

/* =====================================================
   CATEGORY CHIP
===================================================== */

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF2E7D32),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
