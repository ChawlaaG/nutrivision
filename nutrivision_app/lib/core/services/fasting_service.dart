import 'package:shared_preferences/shared_preferences.dart';

class FastingService {
  static const String _keyFastingStart = 'fasting_start_time';
  static const String _keyIsFasting = 'is_fasting';

  Future<void> startFast() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyFastingStart, DateTime.now().millisecondsSinceEpoch);
    await prefs.setBool(_keyIsFasting, true);
  }

  Future<void> endFast() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFasting, false);
    await prefs.remove(_keyFastingStart);
    // Here we could save the completed fast to history
  }

  Future<DateTime?> getStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyFastingStart);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  Future<bool> isFasting() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsFasting) ?? false;
  }
}
