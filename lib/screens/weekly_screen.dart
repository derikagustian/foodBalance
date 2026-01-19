import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:foodbalance/providers/user_provider.dart';

class WeeklyPage extends StatefulWidget {
  const WeeklyPage({super.key});

  @override
  State<WeeklyPage> createState() => _WeeklyPageState();
}

class _WeeklyPageState extends State<WeeklyPage>
    with SingleTickerProviderStateMixin {
  // Controller untuk menangani animasi slide pada TabBar
  late TabController _tabController;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFF4E9A5A);
  static const Color backgroundYellow = Color(0xFFFDF7C3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Listener ini yang membuat IndexedStack berubah saat tab diklik
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

              // Dashboard Utama (Streak & Aktivitas)
              _buildMainDashboard(userProv),

              const SizedBox(height: 25),

              // Tab Bar dengan efek slide
              _buildCustomTabBar(),

              const SizedBox(height: 25),

              // IndexedStack(
              //   index: _tabController.index,
              //   children: [
              //     _buildRingkasanContent(), // Muncul jika pilih "Ringkasan"
              //     _buildGrafikPlaceholder(), // Muncul jika pilih "Grafik"
              //     _buildAIPlaceholder(), // Muncul jika pilih "AI"
              //   ],
              // ),

              // Kartu Statistik Bawah
              // Kartu Statistik Bawah
              Row(
                children: [
                  _buildStatCard(
                    // Mengambil rata-rata dari provider
                    userProv.averageCalories.toStringAsFixed(0),
                    "Rata-rata Kalori Harian",
                    Icons.stacked_line_chart,
                  ),
                  const SizedBox(width: 15),
                  _buildStatCard(
                    // Mengambil total item dari provider
                    userProv.totalFoodItems.toString(),
                    "Makanan Tercatat",
                    Icons.restaurant_menu,
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildMainDashboard(UserProvider userProv) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryGreen,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Atas: Kartu Streak
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              children: [
                _buildLargeStreakCard(
                  userProv.currentStreak
                      .toString(), // Mengambil streak dari Provider
                  "Streak Saat Ini",
                  Icons.local_fire_department,
                ),
                const SizedBox(width: 12),
                _buildLargeStreakCard(
                  "0", // Bisa Anda tambahkan logika longestStreak nanti
                  "Streak Terpanjang",
                  Icons.emoji_events_outlined,
                ),
              ],
            ),
          ),

          // Bagian Bawah: Aktifitas Mingguan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActivityHeader(), // Menampilkan Icon Kalender & Teks
                const SizedBox(height: 15),
                _buildDayDotsRow(userProv), // Menampilkan Titik S-S-R-K-J-S-M
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: accentGreen,
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorSize: TabBarIndicatorSize.tab,

        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),

        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.6),

        // Mengatur font agar lebih tegas
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 13,
        ),

        tabs: [
          const Tab(text: "Ringkasan"),
          const Tab(text: "Grafik"),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
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

  // Widget _buildRingkasanContent() {
  //   return Column(
  //     children: [
  //       Row(
  //         children: [
  //           _buildStatCard("1,200", "Target Kalori", Icons.flag),
  //           const SizedBox(width: 15),
  //           _buildStatCard("850", "Kalori Masuk", Icons.fastfood),
  //         ],
  //       ),
  //       // Jika ingin menambah baris stat lagi di bawahnya
  //       const SizedBox(height: 15),
  //       Row(
  //         children: [
  //           _buildStatCard("75%", "Protein", Icons.fitness_center),
  //           const SizedBox(width: 15),
  //           _buildStatCard("2L", "Air Minum", Icons.water_drop),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildGrafikPlaceholder() {
  //   return Container(
  //     height: 200,
  //     decoration: BoxDecoration(
  //       color: accentGreen.withOpacity(0.2),
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: const Center(
  //       child: Text(
  //         "Grafik Konsumsi Mingguan Akan Muncul di Sini",
  //         textAlign: TextAlign.center,
  //         style: TextStyle(color: primaryGreen),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildAIPlaceholder() {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(color: primaryGreen.withOpacity(0.3)),
  //     ),
  //     child: Row(
  //       children: const [
  //         Icon(Icons.auto_awesome, color: Colors.amber),
  //         SizedBox(width: 10),
  //         Expanded(
  //           child: Text(
  //             "AI: Berdasarkan data minggu ini, tingkatkan konsumsi serat Anda.",
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
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
                fontSize: 35,
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
    return Row(
      children: const [
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
    // Tambah parameter isActive
    return Column(
      children: [
        Text(day, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            // Jika aktif, gunakan warna putih solid, jika tidak gunakan transparan
            color: isActive ? Colors.white : Colors.white24,
            shape: BoxShape.circle,
          ),
          child: isActive
              ? const Icon(
                  Icons.check,
                  size: 15,
                  color: primaryGreen,
                ) // Beri check jika aktif
              : null,
        ),
      ],
    );
  }
}
