import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodbalance/providers/user_provider.dart';
import 'package:foodbalance/widgets/slideUp_animation.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyPage extends StatefulWidget {
  const WeeklyPage({super.key});

  @override
  State<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends State<WeeklyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4E9A5A);
  static const Color backgroundYellow = Color(0xFFFDF7C3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 2) {
          context.read<UserProvider>().fetchAIInsight();
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper untuk mendapatkan inisial hari secara dinamis (7 hari terakhir)
  List<String> _getDynamicDayLabels() {
    const allDays = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    DateTime now = DateTime.now();
    List<String> labels = [];

    for (int i = 6; i >= 0; i--) {
      DateTime date = now.subtract(Duration(days: i));
      // weekday: 1 (Senin) s/d 7 (Minggu)
      labels.add(allDays[date.weekday - 1]);
    }
    return labels;
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: backgroundYellow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Progress",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              Text(
                userProv.weeklyRange,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              EntranceFaded(
                delay: const Duration(milliseconds: 200),
                child: _buildMainDashboard(userProv),
              ),

              const SizedBox(height: 25),

              EntranceFaded(
                delay: const Duration(milliseconds: 400),
                child: _buildCustomTabBar(),
              ),

              const SizedBox(height: 25),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                layoutBuilder:
                    (Widget? currentChild, List<Widget> previousChildren) {
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: EntranceFaded(
                  key: ValueKey<int>(_tabController.index),
                  delay: const Duration(milliseconds: 600),
                  child: _buildTabContent(userProv),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(UserProvider userProv) {
    switch (_tabController.index) {
      case 0:
        return _buildSummaryTab(userProv);
      case 1:
        return _buildGraphTab(userProv);
      case 2:
        return _buildAITab();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- TAB 0: RINGKASAN ---
  Widget _buildSummaryTab(UserProvider userProv) {
    return Row(
      key: const ValueKey(0),
      children: [
        Expanded(
          child: _buildStatCard(
            userProv.averageCalories.toStringAsFixed(0),
            "Rata-rata Kalori",
            Icons.stacked_line_chart,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            userProv.totalFoodItems.toString(),
            "Makanan Tercatat",
            Icons.restaurant_menu,
          ),
        ),
      ],
    );
  }

  // --- TAB 1: GRAFIK DINAMIS ---
  Widget _buildGraphTab(UserProvider userProv) {
    final calorieData = userProv.weeklyCalorieData;
    final dayLabels = _getDynamicDayLabels();

    return Column(
      key: const ValueKey(1),
      children: [
        Container(
          width: double.infinity,
          height: 300,
          padding: const EdgeInsets.only(
            top: 25,
            right: 25,
            left: 10,
            bottom: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              // ============================================================
              // INI ADALAH BAGIAN UNTUK MEMUNCULKAN ANGKA SAAT DI-HOLD/KLIK
              // ============================================================
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true, // Mengaktifkan respon sentuhan
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) =>
                      primaryGreen, // Warna kotak tooltip
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toInt()} kkal', // Angka yang akan muncul
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),

              // ============================================================
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 500,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1000,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt();
                      if (idx >= 0 && idx < dayLabels.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            dayLabels[idx],
                            style: const TextStyle(
                              color: primaryGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                  left: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: calorieData
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value))
                      .toList(),
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: primaryGreen,
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryGreen.withOpacity(0.3),
                        primaryGreen.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 2: AI INSIGHT ---
  // Di dalam _WeeklyPageState, tambahkan pemanggilan saat tab berubah
  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 2) {
      // Panggil fungsi AI hanya saat tab AI (index 2) dibuka
      Provider.of<UserProvider>(context, listen: false).fetchAIInsight();
    }
    setState(() {});
  }

  Widget _buildAITab() {
    final userProv = Provider.of<UserProvider>(context);

    // Jika sedang loading, tampilkan animasi loading yang cantik
    if (userProv.isLoadingAI) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.orange,
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              "Sedang meracik saran kesehatan...",
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      key: const ValueKey(2),
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ), // Border tipis orange
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.orange, size: 40),
          const SizedBox(height: 15),
          const Text(
            "AI PERSONAL COACH",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),

          // Kotak Teks Analisa
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              userProv.aiInsight ??
                  "Geser tab ini untuk mulai menganalisa progres mingguanmu!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.6, // Memberi spasi antar baris agar nyaman dibaca
                color: Colors.grey[800],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

          TextButton.icon(
            onPressed: () => userProv.refreshAI(),
            icon: const Icon(Icons.refresh, size: 18, color: Colors.orange),
            label: const Text(
              "Update Analisa",
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---
  Widget _buildMainDashboard(UserProvider userProv) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                _buildLargeStreakCard(
                  userProv.currentStreak.toString(),
                  "Streak Saat Ini",
                  Icons.local_fire_department,
                ),
                const SizedBox(width: 12),
                _buildLargeStreakCard(
                  "0",
                  "Streak Terpanjang",
                  Icons.emoji_events_outlined,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildActivityHeader(),
                const SizedBox(height: 15),
                _buildDayDotsRow(userProv),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      height: 55,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: accentGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),
        tabs: [
          const Tab(text: "Ringkasan"),
          const Tab(text: "Grafik"),
          const Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 16),
                SizedBox(width: 6),
                Text("AI"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
      decoration: BoxDecoration(
        color: accentGreen,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 35),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStreakCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: accentGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 30),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHeader() {
    return const Row(
      children: [
        Icon(Icons.calendar_month_outlined, color: Colors.white, size: 20),
        SizedBox(width: 8),
        Text(
          "Aktifitas Minggu Ini",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDayDotsRow(UserProvider userProv) {
    List<String> labels = ["S", "S", "R", "K", "J", "S", "M"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        bool active = userProv.isDayActive(index + 1);
        return _buildDayDot(labels[index], active);
      }),
    );
  }

  Widget _buildDayDot(String day, bool isActive) {
    return Column(
      children: [
        Text(day, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white24,
            shape: BoxShape.circle,
          ),
          child: isActive
              ? const Icon(Icons.check, size: 15, color: primaryGreen)
              : null,
        ),
      ],
    );
  }
}
