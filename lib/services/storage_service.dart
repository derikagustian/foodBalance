import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<void> saveProfileToPrefs(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('berat', data['berat']);
    await prefs.setDouble('tinggi', data['tinggi']);
    await prefs.setInt('usia', data['usia']);
    await prefs.setString('jk', data['jk']);
    await prefs.setString('tujuan', data['tujuan']);
    await prefs.setDouble('caloriesTarget', data['caloriesTarget']);
    await prefs.setString('estimasiWaktu', data['estimasiWaktu']);
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
    };
  }

  // AUTO CLEAN UP
  static const String _autoCleanupKey = 'auto_cleanup_days';

  Future<void> saveAutoCleanupSetting(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoCleanupKey, days);
  }

  Future<int?> getAutoCleanupSetting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoCleanupKey);
  }
}
