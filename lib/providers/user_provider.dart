import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:foodbalance/databases/db_helper.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class UserProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  // ==========================================
  // 1. DATA STATE (VARIABEL UTAMA)
  // ==========================================

  // Data Makanan
  List<Map<String, dynamic>> _foodDiary = [];
  List<Map<String, dynamic>> get foodDiary => _foodDiary;

  // Informasi Profil & Target
  double berat = 0;
  double tinggi = 0;
  int usia = 0;
  String jenisKelamin = "";
  String tujuan = "";

  // Hasil Kalkulasi
  double _caloriesTarget = 0;
  String _estimasiWaktu = "-";

  // Mood State
  String _selectedMood = "";
  String _hoveredMood = "";

  bool _notificationShownToday = false;

  // ==========================================
  // 2. CONSTRUCTOR & INITIALIZATION
  // ==========================================

  UserProvider() {
    loadData();
  }

  // ==========================================
  // 3. LOGIKA DATABASE (CRUD)
  // ==========================================

  // ==========================================
  // 3. LOGIKA DATABASE (CRUD)
  // ==========================================
  Future<void> loadData() async {
    final data = await _dbHelper.queryAllFood();

    // Ambil semua data dan ubah format string time ke DateTime
    _foodDiary = data.map((item) {
      Map<String, dynamic> mutableItem = Map.from(item);
      if (mutableItem['time'] is String) {
        mutableItem['time'] = DateTime.parse(mutableItem['time']);
      }
      mutableItem['category'] = mutableItem['category'] ?? 'Cemilan';
      return mutableItem;
    }).toList();

    _foodDiary.sort(
      (a, b) => (b['time'] as DateTime).compareTo(a['time'] as DateTime),
    );

    _notificationShownToday = false;
    _checkCalorieGoal();
    notifyListeners();
  }

  // Tambahkan Method Logika Notifikasi
  void _checkCalorieGoal() {
    if (_caloriesTarget > 0 &&
        totalConsumedCalories >= _caloriesTarget &&
        !_notificationShownToday) {
      // Cetak pesan atau panggil Local Notifications di sini
      debugPrint("NOTIFIKASI: Target tercapai! Sisa waktu: $_estimasiWaktu");

      _notificationShownToday = true;
    }
  }

  // GANTI METHOD addFood LAMA DENGAN INI:
  void addFood({
    required String name,
    required int calories,
    required int protein,
    required int fat,
    required int carb,
    DateTime? manualTime,
  }) async {
    final waktuSimpan = manualTime ?? DateTime.now();

    String kategori = tentukanKategori(waktuSimpan);

    await _dbHelper.insertFood({
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carb': carb,
      'category': kategori,
      'time': waktuSimpan.toIso8601String(),
    });

    await loadData();
  }

  void deleteFood(int id) async {
    await _dbHelper.deleteFood(id);
    await loadData();
  }

  // ==========================================
  // 4. LOGIKA PROFIL & KALKULASI TARGET
  // ==========================================

  double get targetKaloriHarian => _caloriesTarget;
  String get estimasiWaktu => _estimasiWaktu;

  // Getter Target Makro (Dipakai oleh CalorieSummaryCard)
  double get targetKarbo => (_caloriesTarget * 0.5) / 4;
  double get targetProtein => (_caloriesTarget * 0.2) / 4;
  double get targetLemak => (_caloriesTarget * 0.3) / 9;

  void kalkulasiDanSimpan({
    required double bb,
    required double tb,
    required int age,
    required String jk,
    required String goal,
  }) {
    // Rumus Mifflin-St Jeor
    double bmr = (jk == 'Laki - laki')
        ? (10 * bb) + (6.25 * tb) - (5 * age) + 5
        : (10 * bb) + (6.25 * tb) - (5 * age) - 161;

    double tdee = bmr * 1.2;
    double targetBB = tb - 100;

    if (goal == "Turun BB") {
      _caloriesTarget = tdee - 500;
      double selisihBB = bb - targetBB;
      _estimasiWaktu = selisihBB > 0
          ? "${(selisihBB / 0.5).ceil()} Minggu menuju ideal"
          : "Sudah mencapai target";
    } else if (goal == "Naik BB") {
      _caloriesTarget = tdee + 500;
      double selisihBB = targetBB - bb;
      _estimasiWaktu = selisihBB > 0
          ? "${(selisihBB / 0.5).ceil()} Minggu menuju ideal"
          : "Sudah mencapai target";
    } else {
      _caloriesTarget = tdee;
      _estimasiWaktu = "Pertahankan kondisi saat ini";
    }

    notifyListeners();
  }

  // ==========================================
  // 5. LOGIKA KONSUMSI REAL-TIME (GETTER)
  // ==========================================

  double get totalConsumedCalories =>
      todayFoodDiary.fold(0, (sum, item) => sum + item['calories']);

  int get totalConsumedCarbs => todayFoodDiary.fold(
    0,
    (sum, item) => sum + (item['carb'] as num? ?? 0).toInt(),
  );

  int get totalConsumedProtein => todayFoodDiary.fold(
    0,
    (sum, item) => sum + (item['protein'] as num? ?? 0).toInt(),
  );

  int get totalConsumedFat => todayFoodDiary.fold(
    0,
    (sum, item) => sum + (item['fat'] as num? ?? 0).toInt(),
  );

  // ==========================================
  // 6. LOGIKA STATISTIK & STREAK
  // ==========================================

  int get totalFoodItems => _foodDiary.length;

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

  int get daysWithData {
    return _foodDiary.map((e) => (e['time'] as DateTime).day).toSet().length;
  }

  double get averageCalories {
    if (_foodDiary.isEmpty) return 0;
    return totalConsumedCalories / (daysWithData > 0 ? daysWithData : 1);
  }

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

  // ==========================================
  // 7. LOGIKA UI HELPER (DATE & MOOD)
  // ==========================================

  // Mood Getters & Setters
  String get selectedMood => _selectedMood;
  String get hoveredMood => _hoveredMood;

  void updateMood(String moodEmoji) {
    _selectedMood = moodEmoji;
    notifyListeners();
  }

  void setHoveredMood(String emoji) {
    _hoveredMood = emoji;
    notifyListeners();
  }

  // Kategori Waktu
  String tentukanKategori(DateTime waktu) {
    int jam = waktu.hour;
    if (jam >= 5 && jam < 11) return "Sarapan";
    if (jam >= 11 && jam < 15) return "Makan Siang";
    if (jam >= 18 && jam < 22) return "Makan Malam";
    return "Cemilan";
  }

  // Range Mingguan untuk Header
  String get weeklyRange {
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
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

    return (monday.month == sunday.month)
        ? "${monday.day} - ${sunday.day} ${months[monday.month - 1]}"
        : "${monday.day} ${months[monday.month - 1].substring(0, 3)} - ${sunday.day} ${months[sunday.month - 1].substring(0, 3)}";
  }

  // ==========================================
  // 8. LOGIKA RESET (LOGOUT)
  // ==========================================

  void resetUser() {
    // Reset Data Makanan (UI State)
    _foodDiary = [];

    // Reset Profil & Target
    berat = 0;
    tinggi = 0;
    usia = 0;
    jenisKelamin = "";
    tujuan = "";

    // Reset Hasil Kalkulasi
    _caloriesTarget = 0;
    _estimasiWaktu = "-";

    // Reset Mood
    _selectedMood = "";
    _hoveredMood = "";

    // Beritahu semua widget untuk update tampilan jadi kosong
    notifyListeners();
  }

  // JIKA ingin menghapus SEMUA riwayat makan di HP saat logout:
  Future<void> clearAllData() async {
    await _dbHelper.deleteAllFood();
    resetUser();
    await loadData();
  }

  // ==========================================
  // 9. LOGIKA MOOD TRACK
  // ==========================================
  bool _isLoadingAi = false;
  bool get isLoadingAi => _isLoadingAi;

  Future<String> getAiFoodRecommendation(String mood) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

    if (apiKey.isEmpty) {
      debugPrint("Error: API Key tidak ditemukan di .env");
      return "Konfigurasi AI belum siap. Coba cek file .env kamu!";
    }

    _isLoadingAi = true;
    notifyListeners();

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        ],
      );

      // Prompt yang sudah kamu buat sudah bagus, santai namun informatif
      final prompt =
          """
  Role: Ahli Gizi Profesional.
  Konteks: Pengguna sedang merasa $mood dan memiliki tujuan kesehatan: $tujuan.
  Tugas: Rekomendasikan 1 menu makanan sehat yang spesifik.
  Format Jawaban: 
  - Nama Makanan: (Sebutkan namanya)
  - Alasan: (Berikan alasan medis/kesehatan singkat kenapa cocok dengan mood $mood dalam 2 kalimat).
  Catatan: Jangan memberikan jawaban satu kata atau reaksi singkat. Gunakan Bahasa Indonesia.
""";

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      _isLoadingAi = false;
      notifyListeners();

      // Membersihkan teks dari spasi berlebih atau karakter aneh jika ada
      return response.text?.trim() ??
          "Coba makan buah segar ya agar tetap sehat!";
    } catch (e) {
      debugPrint("Gemini Error: $e"); // Membantu saat debugging
      _isLoadingAi = false;
      notifyListeners();
      return "Duh, AI sedang istirahat. Coba lagi nanti ya!";
    }
  }

  // ==========================================
  // 10. LOGIKA PENDING FOOD
  // ==========================================
  // Di dalam UserProvider
  Map<String, dynamic>? _pendingFood;
  Map<String, dynamic>? get pendingFood => _pendingFood;

  // Fungsi untuk menyimpan draft scan
  void setPendingFood(Map<String, dynamic>? foodData) {
    _pendingFood = foodData;
    notifyListeners();
  }

  // Fungsi untuk menghapus draft setelah disimpan atau dibatalkan
  void clearPendingFood() {
    _pendingFood = null;
    notifyListeners();
  }

  // ==========================================
  // 11. LOGIKA DATa HARI INI
  // ==========================================
  List<Map<String, dynamic>> get todayFoodDiary {
    final now = DateTime.now();
    return _foodDiary.where((item) {
      final DateTime itemDate = item['time'] is DateTime
          ? item['time']
          : DateTime.parse(item['time'].toString());
      return itemDate.year == now.year &&
          itemDate.month == now.month &&
          itemDate.day == now.day;
    }).toList();
  }
}
