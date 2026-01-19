import 'package:flutter/material.dart';
import 'package:foodbalance/databases/db_helper.dart';

class UserProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  List<Map<String, dynamic>> _foodDiary = [];

  // Ambil data dari list lokal
  List<Map<String, dynamic>> get foodDiary => _foodDiary;

  // Variabel Profil User
  double berat = 0;
  double tinggi = 0;
  int usia = 0;
  String jenisKelamin = "";
  String tujuan = "";
  double targetKaloriHarian = 0;

  // Constructor: Langsung panggil loadData saat aplikasi dibuka
  UserProvider() {
    loadData();
  }

  // --- LOGIKA DATABASE ---

  // Memuat data dari SQLite ke dalam List aplikasi
  Future<void> loadData() async {
    final data = await _dbHelper.queryAllFood();
    _foodDiary = data.map((item) {
      Map<String, dynamic> mutableItem = Map.from(item);
      // Mengubah String waktu dari DB kembali ke objek DateTime
      mutableItem['time'] = DateTime.parse(mutableItem['time']);
      mutableItem['category'] = mutableItem['category'] ?? 'Cemilan';
      return mutableItem;
    }).toList();
    _foodDiary.sort(
      (a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime),
    );
    notifyListeners();
  }

  // Menambah makanan ke Database dan UI
  void addFood({
    required String name,
    required int calories,
    required int protein,
    required int fat,
    required int carb,
  }) async {
    final now = DateTime.now();

    // Tentukan kategori secara otomatis sebelum disimpan
    String kategori = tentukanKategori(now);

    await _dbHelper.insertFood({
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carb': carb,
      'category': kategori,
      'time': now.toIso8601String(),
    });

    await loadData();
  }

  // Menghapus makanan berdasarkan ID database
  void deleteFood(int id) async {
    await _dbHelper.deleteFood(id);
    await loadData();
  }

  // --- LOGIKA KALKULASI & STATISTIK ---

  double get targetKarbo => (targetKaloriHarian * 0.5) / 4;
  double get targetProtein => (targetKaloriHarian * 0.2) / 4;
  double get targetLemak => (targetKaloriHarian * 0.3) / 9;

  double get totalConsumedCalories =>
      _foodDiary.fold(0, (sum, item) => sum + item['calories']);

  int get totalConsumedCarbs =>
      _foodDiary.fold(0, (sum, item) => sum + (item['carb'] as int));

  int get totalConsumedProtein =>
      _foodDiary.fold(0, (sum, item) => sum + (item['protein'] as int));

  int get totalConsumedFat =>
      _foodDiary.fold(0, (sum, item) => sum + (item['fat'] as int));

  int get totalFoodItems => _foodDiary.length;

  int get daysWithData {
    return _foodDiary.map((e) => (e['time'] as DateTime).day).toSet().length;
  }

  double get averageCalories {
    if (_foodDiary.isEmpty) return 0;
    return totalConsumedCalories / (daysWithData > 0 ? daysWithData : 1);
  }

  // --- LOGIKA AKTIFITAS MINGGUAN ---

  bool isDayActive(int dayOfWeek) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final targetDate = startOfWeek.add(Duration(days: dayOfWeek - 1));

    return _foodDiary.any((makanan) {
      final tgl = makanan['time'] as DateTime;
      return tgl.day == targetDate.day &&
          tgl.month == targetDate.month &&
          tgl.year == targetDate.year;
    });
  }

  // --- LOGIKA STREAK ---

  int get currentStreak {
    if (_foodDiary.isEmpty) return 0;
    int streak = 0;
    DateTime checkDate = DateTime.now();

    while (true) {
      bool hasFood = _foodDiary.any((makanan) {
        final tgl = makanan['time'] as DateTime;
        return tgl.day == checkDate.day &&
            tgl.month == checkDate.month &&
            tgl.year == checkDate.year;
      });

      if (hasFood) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // --- LOGIKA MOOD ---

  String _selectedMood = "";
  String get selectedMood => _selectedMood;
  String _hoveredMood = "";
  String get hoveredMood => _hoveredMood;

  void updateMood(String moodEmoji) {
    _selectedMood = moodEmoji;
    notifyListeners();
  }

  void setHoveredMood(String emoji) {
    _hoveredMood = emoji;
    notifyListeners();
  }

  // --- KALKULASI PROFIL ---

  void kalkulasiDanSimpan({
    required double bb,
    required double tb,
    required int age,
    required String jk,
    required String goal,
  }) {
    berat = bb;
    tinggi = tb;
    usia = age;
    jenisKelamin = jk;
    tujuan = goal;

    double bmr = (jenisKelamin == "Laki - laki")
        ? 66 + (13.7 * berat) + (5 * tinggi) - (6.8 * usia)
        : 655 + (9.6 * berat) + (1.8 * tinggi) - (4.7 * usia);

    double tdee = bmr * 1.2;
    if (tujuan == "Naik BB")
      targetKaloriHarian = tdee + 500;
    else if (tujuan == "Turun BB")
      targetKaloriHarian = tdee - 500;
    else
      targetKaloriHarian = tdee;

    notifyListeners();
  }

  // daily kategori
  String tentukanKategori(DateTime waktu) {
    int jam = waktu.hour;

    if (jam >= 5 && jam < 11) return "Sarapan";
    if (jam >= 11 && jam < 15) return "Makan Siang";
    if (jam >= 18 && jam < 22) return "Makan Malam";
    return "Cemilan"; // Selain jam di atas, masuk ke Cemilan
  }

  // tanggal mingguan
  String get weeklyRange {
    DateTime now = DateTime.now();
    // Mencari hari Senin di minggu ini
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    // Mencari hari Minggu di minggu ini
    DateTime sunday = monday.add(const Duration(days: 6));

    List<String> months = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];

    if (monday.month == sunday.month) {
      return "${monday.day} - ${sunday.day} ${months[monday.month - 1]}";
    } else {
      return "${monday.day} ${months[monday.month - 1].substring(0, 3)} - ${sunday.day} ${months[sunday.month - 1].substring(0, 3)}";
    }
  }
}
