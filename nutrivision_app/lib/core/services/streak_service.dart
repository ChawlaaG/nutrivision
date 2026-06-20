import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StreakService {
  static const String _keyStreak = 'user_streak';
  static const String _keyLastLogDate = 'last_log_date';

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreak) ?? 0;
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogDateStr = prefs.getString(_keyLastLogDate);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastLogDateStr == todayStr) {
      // Already logged today
      return;
    }

    int currentStreak = prefs.getInt(_keyStreak) ?? 0;

    if (lastLogDateStr != null) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);

      if (lastLogDateStr == yesterdayStr) {
        // Logged yesterday, increment streak
        currentStreak++;
      } else {
        // Missed a day (or more), reset streak
        // Note: If we want to be lenient, we could check if it's within 48 hours
        currentStreak = 1; 
      }
    } else {
      // First log ever
      currentStreak = 1;
    }

    await prefs.setInt(_keyStreak, currentStreak);
    await prefs.setString(_keyLastLogDate, todayStr);
  }
}
