import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:foodbalance/widgets/slideUp_animation.dart';

class DailyLogPage extends StatefulWidget {
  const DailyLogPage({super.key});

  @override
  State<DailyLogPage> createState() => _DailyLogPageState();
}

class _DailyLogPageState extends State<DailyLogPage> {
  DateTime _selectedDate = DateTime.now();

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color backgroundYellow = Color(0xFFFDF7C3);

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryGreen,
              onPrimary: Colors.white,
              onSurface: primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();

    final filteredFoods = userProv.foodDiary.where((food) {
      final foodDate = food['time'] as DateTime;
      return foodDate.day == _selectedDate.day &&
          foodDate.month == _selectedDate.month &&
          foodDate.year == _selectedDate.year;
    }).toList();

    return Scaffold(
      backgroundColor: backgroundYellow,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER TITLE ---
            const Padding(
              padding: EdgeInsets.only(left: 20, top: 20),
              child: Text(
                "Daily Log",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- DATE NAVIGATOR ---
            _buildDateNavigator(),

            const SizedBox(height: 20),

            // --- LOG CARDS LIST ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  EntranceFaded(
                    delay: const Duration(milliseconds: 200),
                    child: _buildLogCard("Sarapan", filteredFoods),
                  ),
                  EntranceFaded(
                    delay: const Duration(milliseconds: 400),
                    child: _buildLogCard("Cemilan", filteredFoods),
                  ),
                  EntranceFaded(
                    delay: const Duration(milliseconds: 600),
                    child: _buildLogCard("Makan Siang", filteredFoods),
                  ),
                  EntranceFaded(
                    delay: const Duration(milliseconds: 800),
                    child: _buildLogCard("Makan Malam", filteredFoods),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Navigator Tanggal yang bisa di-klik
  Widget _buildDateNavigator() {
    String dateDisplay;
    final now = DateTime.now();

    // Cek apakah hari ini
    if (DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(now)) {
      dateDisplay = "Today";
    } else {
      dateDisplay = DateFormat('dd MMM yyyy').format(_selectedDate);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tombol Previous
            IconButton(
              onPressed: () => _changeDate(-1),
              icon: const Icon(
                Icons.arrow_circle_left,
                color: primaryGreen,
                size: 35,
              ),
            ),

            // Area Tengah (Klik untuk Kalender)
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateDisplay,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tombol Next
            IconButton(
              onPressed: () => _changeDate(1),
              icon: const Icon(
                Icons.arrow_circle_right,
                color: primaryGreen,
                size: 35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(String categoryName, List<Map<String, dynamic>> foods) {
    final categoryItems = foods
        .where((f) => f['category'] == categoryName)
        .toList();

    // Hitung total kalori per kategori
    int totalKkal = categoryItems.fold(
      0,
      (sum, item) => sum + (item['calories'] as int),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (categoryItems.isNotEmpty)
                Text(
                  "$totalKkal kkal",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (categoryItems.isEmpty)
            const Text(
              "Belum ada catatan",
              style: TextStyle(color: Colors.white60, fontSize: 12),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categoryItems.length,
              itemBuilder: (context, index) {
                final item = categoryItems[index];
                String formattedTime = DateFormat('HH:mm').format(item['time']);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -4),
                  leading: Text(
                    formattedTime,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  title: Text(
                    item['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Text(
                    "${item['calories']} kkal",
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
