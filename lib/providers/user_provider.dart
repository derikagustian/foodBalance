import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodbalance/databases/db_helper.dart';
import 'package:foodbalance/services/ai_service.dart';
import 'package:foodbalance/services/storage_service.dart';
import 'package:foodbalance/services/firebase_service.dart';

class UserProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();
  final FirebaseService _firebaseService = FirebaseService();

  // ==========================================
  // 1. DATA STATE (VARIABEL UTAMA)
  // ==========================================
  List<Map<String, dynamic>> _foodDiary = [];
  List<Map<String, dynamic>> get foodDiary => _foodDiary;

  double berat = 0;
  double tinggi = 0;
  int usia = 0;
  String jenisKelamin = "";
  String tujuan = "";

  double _caloriesTarget = 0;
  String _estimasiWaktu = "Data Belum Lengkap";

  String _selectedMood = "";
  String _hoveredMood = "";

  bool _notificationShownToday = false;
  bool get isProfileComplete => berat > 0 && tinggi > 0 && usia > 0;

  DateTime? _targetDate;

  // ==========================================
  // 2. CONSTRUCTOR & INITIALIZATION
  // ==========================================
  UserProvider() {
    _initializeProvider();
  }

  // ==========================================
  // 3. LOGIKA DATABASE (CRUD)
  // ==========================================
  Future<void> loadData() async {
    final data = await _dbHelper.queryAllFood();

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
    _updateEstimasiWaktu();
    notifyListeners();
  }

  void _checkCalorieGoal() {
    if (_caloriesTarget > 0 &&
        totalConsumedCalories >= _caloriesTarget &&
        !_notificationShownToday) {
      debugPrint("NOTIFIKASI: Target tercapai! Sisa waktu: $_estimasiWaktu");
      _notificationShownToday = true;
    }
  }

  VoidCallback? onGoalReached;

  void addFood({
    required String name,
    required int calories,
    required int protein,
    required int fat,
    required int carb,
    DateTime? manualTime,
  }) async {
    bool wasGoalReachedBefore = totalConsumedCalories >= _caloriesTarget;
    final waktuSimpan = manualTime ?? DateTime.now();
    String kategori = tentukanKategori(waktuSimpan);

    final Map<String, dynamic> foodMap = {
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carb': carb,
      'category': kategori,
      'time': waktuSimpan.toIso8601String(),
    };

    String? firebaseId = await _firebaseService.backupFoodItem(foodMap);

    foodMap['firebase_id'] = firebaseId;

    await _dbHelper.insertFood(foodMap);

    await loadData();

    if (!wasGoalReachedBefore &&
        totalConsumedCalories >= _caloriesTarget &&
        _caloriesTarget > 0) {
      if (onGoalReached != null) {
        onGoalReached!();
      }
    }
  }

  // Di UserProvider.dart
  void deleteFood(int localId) async {
    // Hanya 1 parameter
    try {
      // Cari item lengkap berdasarkan localId dari list yang sudah ada di memori
      final foodItem = _foodDiary.firstWhere((item) => item['id'] == localId);
      String? fId = foodItem['firebase_id'];

      // 1. Hapus di Firebase (Cloud)
      if (fId != null && fId.isNotEmpty) {
        await _firebaseService.deleteFoodItem(fId);
      }

      // 2. Hapus di SQLite (Lokal)
      await _dbHelper.deleteFood(localId);

      // 3. Refresh data
      await loadData();
    } catch (e) {
      debugPrint("Error hapus: $e");
    }
  }

  // ==========================================
  // 4. LOGIKA PROFIL & KALKULASI TARGET
  // ==========================================
  double get targetKaloriHarian => _caloriesTarget;
  String get estimasiWaktu => _estimasiWaktu;
  double get targetKarbo => (_caloriesTarget * 0.5) / 4;
  double get targetProtein => (_caloriesTarget * 0.2) / 4;
  double get targetLemak => (_caloriesTarget * 0.3) / 9;

  Future<void> kalkulasiDanSimpan({
    required double bb,
    required double tb,
    required int age,
    required String jk,
    required String goal,
  }) async {
    this.berat = bb;
    this.tinggi = tb;
    this.usia = age;
    this.jenisKelamin = jk;
    this.tujuan = goal;

    double bmr = (jk == 'Laki - laki')
        ? (10 * bb) + (6.25 * tb) - (5 * age) + 5
        : (10 * bb) + (6.25 * tb) - (5 * age) - 161;

    double tdee = bmr * 1.2;

    if (goal == "Turun BB") {
      _caloriesTarget = tdee - 500;
    } else if (goal == "Naik BB") {
      _caloriesTarget = tdee + 500;
    } else {
      _caloriesTarget = tdee;
    }

    double faktorPenyusut = (jk == 'Laki - laki') ? 0.10 : 0.15;
    double targetBB = (tb - 100) - ((tb - 100) * faktorPenyusut);

    if (goal == "Turun BB" || goal == "Naik BB") {
      double selisihBB = (goal == "Turun BB")
          ? (bb - targetBB)
          : (targetBB - bb);
      if (selisihBB <= 0.2) {
        _estimasiWaktu = "Target Tercapai! 🎉";
        _targetDate = null;
      } else {
        int totalMinggu = (selisihBB / 0.5).ceil();
        _targetDate = DateTime.now().add(Duration(days: totalMinggu * 7));
        _updateEstimasiWaktu();
      }
    }

    // 5. SIMPAN DAN NOTIFIKASI
    await _saveProfileToPrefs();
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

  int get daysWithData =>
      _foodDiary.map((e) => (e['time'] as DateTime).day).toSet().length;
  double get averageCalories => _foodDiary.isEmpty
      ? 0
      : totalConsumedCalories / (daysWithData > 0 ? daysWithData : 1);

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
  // 7. LOGIKA UI HELPER
  // ==========================================
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

  String tentukanKategori(DateTime waktu) {
    int jam = waktu.hour;
    if (jam >= 5 && jam < 11) return "Sarapan";
    if (jam >= 11 && jam < 15) return "Makan Siang";
    if (jam >= 18 && jam < 22) return "Makan Malam";
    return "Cemilan";
  }

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
    _foodDiary = [];
    berat = 0;
    tinggi = 0;
    usia = 0;
    jenisKelamin = "";
    tujuan = "";
    _caloriesTarget = 0;
    _estimasiWaktu = "Data Belum Lengkap";
    _selectedMood = "";
    _hoveredMood = "";
    _targetDate = null;
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _dbHelper.deleteAllFood();
    resetUser();
    await loadData();
  }

  // ==========================================
  // 9. LOGIKA MOOD TRACK (MENGGUNAKAN SERVICE)
  // ==========================================
  bool _isLoadingAi = false;
  bool get isLoadingAi => _isLoadingAi;

  Future<String> getAiFoodRecommendation(String mood) async {
    _isLoadingAi = true;
    notifyListeners();

    final result = await _aiService.getAiFoodRecommendation(mood, tujuan);

    _isLoadingAi = false;
    notifyListeners();
    return result;
  }

  // ==========================================
  // 10. LOGIKA PENDING FOOD
  // ==========================================
  Map<String, dynamic>? _pendingFood;
  Map<String, dynamic>? get pendingFood => _pendingFood;

  void setPendingFood(Map<String, dynamic> data) {
    _pendingFood = data;
    notifyListeners();
  }

  void clearPendingFood() {
    _pendingFood = null;
    notifyListeners();
  }

  // ==========================================
  // 11. LOGIKA SYNC PENDING (LOGKAL KE CLOUD)
  // ==========================================
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<void> syncPendingData() async {
    if (_isSyncing) return;

    final pendingItems = await _dbHelper.getPendingFood();
    if (pendingItems.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    for (var item in pendingItems) {
      try {
        final Map<String, dynamic> dataToUpload = Map.from(item);
        final int localId = dataToUpload['id'];

        // Bersihkan data sebelum upload
        dataToUpload.remove('id');
        dataToUpload.remove('firebase_id');

        String? fId = await _firebaseService.backupFoodItem(dataToUpload);

        if (fId != null) {
          await _dbHelper.updateFirebaseId(localId, fId);
        }
      } catch (e) {
        debugPrint("Gagal sinkron item: $e");
      }
    }

    _isSyncing = false;
    await loadData();
    notifyListeners();
  }

  // ==========================================
  // 12. LOGIKA DATA HARI INI
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

  // ==========================================
  // 13. LOGIKA STORAGE (MENGGUNAKAN SERVICE)
  // ==========================================
  Future<void> loadProfile() async {
    final data = await _storageService.loadProfileFromPrefs();
    berat = data['berat'];
    tinggi = data['tinggi'];
    usia = data['usia'];
    jenisKelamin = data['jk'];
    tujuan = data['tujuan'];
    _caloriesTarget = data['caloriesTarget'];
    _estimasiWaktu = data['estimasiWaktu'];
    if (data['targetDate'] != null) {
      _targetDate = DateTime.parse(data['targetDate']);
    }
    _updateEstimasiWaktu();
    notifyListeners();
  }

  Future<void> _saveProfileToPrefs({bool syncToFirebase = true}) async {
    final profileMap = {
      'berat': berat,
      'tinggi': tinggi,
      'usia': usia,
      'jk': jenisKelamin,
      'tujuan': tujuan,
      'caloriesTarget': _caloriesTarget,
      'estimasiWaktu': _estimasiWaktu,
      'targetDate': _targetDate?.toIso8601String(),
    };

    // Simpan ke SharedPreferences (Lokal)
    await _storageService.saveProfileToPrefs(profileMap);

    // HANYA kirim ke Firebase jika diinstruksikan (Default: true)
    if (syncToFirebase) {
      await _firebaseService.syncProfile(profileMap);
    }
  }

  // ==========================================
  // 14. LOGIKA WEEKLY (GRAFIK & AI)
  // ==========================================
  List<double> get weeklyCalorieData {
    List<double> dailyTotals = List.filled(7, 0.0);
    DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    for (var food in _foodDiary) {
      DateTime foodDate = food['time'] as DateTime;
      int difference = today
          .difference(DateTime(foodDate.year, foodDate.month, foodDate.day))
          .inDays;
      if (difference >= 0 && difference < 7)
        dailyTotals[6 - difference] += (food['calories'] as num).toDouble();
    }
    return dailyTotals;
  }

  String get _weeklyMacroAnalysis {
    if (_foodDiary.isEmpty) return "Tidak ada data makro.";
    double p = _foodDiary.fold(
      0,
      (s, i) => s + (i['protein'] as num).toDouble(),
    );
    double c = _foodDiary.fold(0, (s, i) => s + (i['carb'] as num).toDouble());
    double f = _foodDiary.fold(0, (s, i) => s + (i['fat'] as num).toDouble());
    int d = daysWithData > 0 ? daysWithData : 1;
    return "Rata-rata: Protein ${(p / d).toStringAsFixed(1)}g, Karbo ${(c / d).toStringAsFixed(1)}g, Lemak ${(f / d).toStringAsFixed(1)}g";
  }

  String get _eatingPattern {
    Map<String, int> counts = {};
    for (var food in _foodDiary) {
      String cat = food['category'] ?? 'Cemilan';
      counts[cat] = (counts[cat] ?? 0) + 1;
    }
    return counts.toString();
  }

  // ==========================================
  // 15. PEMANGGILAN AI SERVICE
  // ==========================================
  String? _aiInsight;
  bool _isLoadingAI = false;
  String? get aiInsight => _aiInsight;
  bool get isLoadingAI => _isLoadingAI;

  Future<void> fetchAIInsight() async {
    if (_aiInsight != null) return;
    _isLoadingAI = true;
    notifyListeners();

    final prompt =
        """
      Identitas: $jenisKelamin, $usia thn. Tujuan: $tujuan. Target: ${_caloriesTarget.toStringAsFixed(0)} kkal.
      Realita: Rata-rata ${averageCalories.toStringAsFixed(0)} kkal. Pola: $_eatingPattern. Makro: $_weeklyMacroAnalysis. Tren: $weeklyCalorieData.
      Tugas: Ahli gizi, berikan analisa kritis & santai (maks 3 kalimat). Indonesia.
    """;

    _aiInsight = await _aiService.fetchAIInsight(prompt);
    _isLoadingAI = false;
    notifyListeners();
  }

  void refreshAI() {
    _aiInsight = null;
    fetchAIInsight();
  }

  // ==========================================
  // 16. LOGIKA CLEANUP
  // ==========================================
  Future<void> cleanupData(int days) async {
    try {
      if (days == 0) {
        await _dbHelper.deleteAllFood();
      } else {
        await _dbHelper.deleteOldData(days);
      }

      await loadData();
    } catch (e) {
      debugPrint("Gagal cleanupData: $e");
    }
  }

  Future<void> setAutoCleanupDays(int days) async {
    await _storageService.saveAutoCleanupSetting(days);

    await cleanupData(days);

    notifyListeners();
  }

  // ==========================================
  // 17. LOGIKA UPDATE WAKTU TARGET CAPAIAN
  // ==========================================
  void _updateEstimasiWaktu() {
    // Jika profil belum lengkap, jangan set estimasi waktu dulu
    if (!isProfileComplete) {
      _estimasiWaktu = "Lengkapi Profil";
      return;
    }

    if (_targetDate == null) {
      // Jika profil lengkap tapi tidak ada targetDate (mungkin Jaga BB)
      _estimasiWaktu = "Pertahankan Berat Badan Ideal! 🎉";
      return;
    }

    final now = DateTime.now();
    final difference = _targetDate!.difference(now);
    final sisaHari = (difference.inHours / 24).ceil();

    if (sisaHari <= 0) {
      _estimasiWaktu = "Target Tercapai! 🎉";
    } else if (sisaHari < 7) {
      _estimasiWaktu = "$sisaHari Hari lagi menuju ideal";
    } else {
      _estimasiWaktu = "${(sisaHari / 7).ceil()} Minggu lagi menuju ideal";
    }
  }

  // ==========================================
  // 18. LOGIKA SINKRONISASI AKUN
  // ==========================================
  Future<void> syncDataFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await syncPendingData();

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        if (data['profile'] != null) {
          final p = data['profile'] as Map<String, dynamic>;

          berat = (p['berat'] as num?)?.toDouble() ?? 0.0;
          tinggi = (p['tinggi'] as num?)?.toDouble() ?? 0.0;
          usia = (p['usia'] as num?)?.toInt() ?? 0;
          jenisKelamin = p['jk'] ?? "";
          tujuan = p['tujuan'] ?? "";
          _caloriesTarget = (p['caloriesTarget'] as num?)?.toDouble() ?? 0.0;

          if (p['targetDate'] != null) {
            _targetDate = DateTime.parse(p['targetDate']);
          }

          _updateEstimasiWaktu();
          await _saveProfileToPrefs(syncToFirebase: false);
        }

        final foodSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('food_diary')
            .get();

        await _dbHelper.deleteAllFood();

        if (foodSnapshot.docs.isNotEmpty) {
          for (var doc in foodSnapshot.docs) {
            final foodData = doc.data();

            await _dbHelper.insertFood({
              'name': foodData['name'],
              'calories': foodData['calories'],
              'protein': foodData['protein'],
              'fat': foodData['fat'],
              'carb': foodData['carb'],
              'category': foodData['category'],
              'time': foodData['time'],
              'firebase_id': doc.id,
            });
          }
          await loadData();
        }

        notifyListeners();
        debugPrint("Sync Berhasil: Data lokal sekarang identik dengan Cloud.");
      }
    } catch (e) {
      debugPrint("Error sync: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  int _backupInterval = 30;
  int get backupInterval => _backupInterval;

  bool _isAutoBackingUp = false;
  bool get isAutoBackingUp => _isAutoBackingUp;

  Future<void> setBackupInterval(int days) async {
    _backupInterval = days;
    await _storageService.saveBackupInterval(days);
    notifyListeners();
  }

  Future<void> checkAndRunAutoBackup() async {
    final lastBackupStr = await _storageService.getLastBackupDate();

    if (lastBackupStr == null) {
      await runFullBackup();
      return;
    }

    final now = DateTime.now();
    final lastBackup = DateTime.parse(lastBackupStr);

    final today = DateTime(now.year, now.month, now.day);
    final lastBackupDateOnly = DateTime(
      lastBackup.year,
      lastBackup.month,
      lastBackup.day,
    );

    final daysSinceLastBackup = today.difference(lastBackupDateOnly).inDays;

    if (daysSinceLastBackup >= _backupInterval) {
      debugPrint(
        "🚀 Menjalankan Backup Otomatis (Interval: $_backupInterval hari)",
      );
      await runFullBackup();
    }
  }

  Future<void> runFullBackup() async {
    _isAutoBackingUp = true;
    notifyListeners();

    try {
      await syncPendingData();
      await _storageService.saveLastBackupDate(
        DateTime.now().toIso8601String(),
      );
    } finally {
      _isAutoBackingUp = false;
      notifyListeners();
    }
  }

  Future<void> _initializeProvider() async {
    try {
      await Future.wait([loadData(), loadProfile()]);

      final savedInterval = await _storageService.getBackupInterval();
      _backupInterval = savedInterval ?? 30;

      Future.delayed(const Duration(seconds: 5), () async {
        await checkAndRunAutoBackup();
      });

      notifyListeners();
    } catch (e) {
      debugPrint("Error saat inisialisasi Provider: $e");
    }
  }
}
