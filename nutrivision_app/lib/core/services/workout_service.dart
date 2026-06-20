import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class WorkoutService {
  static const String _keyDailyExercise = 'daily_exercise_calories';
  static const String _keyLastExerciseDate = 'last_exercise_date';

  // Get calories burned today
  Future<int> getCaloriesBurnedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_keyLastExerciseDate);

    if (lastDate != today) {
      return 0; // New day, reset
    }

    return prefs.getInt(_keyDailyExercise) ?? 0;
  }

  // Add calories burned
  Future<void> logWorkout(int calories) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = prefs.getString(_keyLastExerciseDate);

    int current = 0;
    if (lastDate == today) {
      current = prefs.getInt(_keyDailyExercise) ?? 0;
    }

    await prefs.setInt(_keyDailyExercise, current + calories);
    await prefs.setString(_keyLastExerciseDate, today);
  }

  // Clear workout for today (optional, for testing)
  Future<void> clearToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDailyExercise);
  }
}
