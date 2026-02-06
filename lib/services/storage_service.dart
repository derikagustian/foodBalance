import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Key Constants
  static const String _autoCleanupKey = 'auto_cleanup_days';
  static const String _backupIntervalKey = 'backup_interval_days';
  static const String _lastBackupDateKey = 'last_backup_date';
  static const String _reminderStatusKey = 'reminder_active';

  // --- PROFILE LOGIC ---
  Future<void> saveProfileToPrefs(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('berat', data['berat']);
    await prefs.setDouble('tinggi', data['tinggi']);
    await prefs.setInt('usia', data['usia']);
    await prefs.setString('jk', data['jk']);
    await prefs.setString('tujuan', data['tujuan']);
    await prefs.setDouble('caloriesTarget', data['caloriesTarget']);
    await prefs.setString('estimasiWaktu', data['estimasiWaktu']);

    if (data['targetDate'] != null) {
      await prefs.setString('targetDate', data['targetDate']);
    }
  }

  Future<Map<String, dynamic>> loadProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'berat': prefs.getDouble('berat') ?? 0.0,
      'tinggi': prefs.getDouble('tinggi') ?? 0.0,
      'usia': prefs.getInt('usia') ?? 0,
      'jk': prefs.getString('jk') ?? "",
      'tujuan': prefs.getString('tujuan') ?? "",
      'caloriesTarget': prefs.getDouble('caloriesTarget') ?? 0.0,
      'estimasiWaktu': prefs.getString('estimasiWaktu') ?? "-",
      'targetDate': prefs.getString('targetDate'),
    };
  }

  // --- AUTO CLEAN UP ---
  Future<void> saveAutoCleanupSetting(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoCleanupKey, days);
  }

  Future<int?> getAutoCleanupSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoCleanupKey);
  }

  // --- AUTO BACKUP LOGIC (NEW) ---

  /// Menyimpan interval hari untuk backup (misal: 30, 90)
  Future<void> saveBackupInterval(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backupIntervalKey, days);
  }

  /// Mengambil interval backup, default 30 hari jika belum diatur
  Future<int?> getBackupInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('backup_interval_days');
  }

  /// Menyimpan tanggal terakhir backup dalam format ISO8601 String
  Future<void> saveLastBackupDate(String dateIso) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupDateKey, dateIso);
  }

  /// Mengambil tanggal terakhir backup
  Future<String?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastBackupDateKey);
  }

  // --- REMINDER LOGIC ---
  Future<void> saveReminderStatus(bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderStatusKey, isActive);
  }

  Future<bool> getReminderStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderStatusKey) ?? false;
  }
}
