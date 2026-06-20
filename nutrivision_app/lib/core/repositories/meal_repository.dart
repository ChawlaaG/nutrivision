import '../services/database_service.dart';
import '../models/meal.dart';

class MealRepository {
  final DatabaseService _db = DatabaseService();

  Future<int> addMeal(Meal meal) async {
    return await _db.insert('meals', meal.toMap());
  }

  Future<int> deleteMeal(int id) async {
    return await _db.delete('meals', 'id = ?', [id]);
  }

  Future<int> updateMeal(Meal meal) async {
    return await _db.update('meals', meal.toMap(), 'id = ?', [meal.id]);
  }

  Future<List<Meal>> getMealsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).millisecondsSinceEpoch;

    final maps = await _db.query(
      'meals',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'timestamp DESC',
    );

    return maps.map((e) => Meal.fromMap(e)).toList();
  }

  Future<Map<String, int>> getDailyMacros(DateTime date) async {
    final meals = await getMealsForDate(date);
    int calories = 0, protein = 0, carbs = 0, fat = 0;

    for (var meal in meals) {
      calories += meal.calories;
      protein += meal.protein;
      carbs += meal.carbs;
      fat += meal.fat;
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
  
  // Get meals for a range (for weekly stats)
  Future<List<Meal>> getMealsForRange(DateTime start, DateTime end) async {
    final startMillis = start.millisecondsSinceEpoch;
    final endMillis = end.millisecondsSinceEpoch;

    final maps = await _db.query(
      'meals',
      where: 'timestamp BETWEEN ? AND ?',
      whereArgs: [startMillis, endMillis],
      orderBy: 'timestamp ASC',
    );

    return maps.map((e) => Meal.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getWeeklyStats() async {
    final now = DateTime.now();
    // Start from 6 days ago to include today (7 days total)
    final start = now.subtract(const Duration(days: 6));
    // Normalize to start of day
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final meals = await getMealsForRange(startDate, endDate);
    
    // Initialize stats for each day
    List<Map<String, dynamic>> stats = [];
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      stats.add({
        'date': date.toIso8601String(),
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      });
    }

    // Aggregate meal data
    for (var meal in meals) {
      // Find the corresponding day in stats
      final mealDate = DateTime(meal.timestamp.year, meal.timestamp.month, meal.timestamp.day);
      final dayIndex = mealDate.difference(startDate).inDays;
      
      if (dayIndex >= 0 && dayIndex < 7) {
        stats[dayIndex]['calories'] = (stats[dayIndex]['calories'] as int) + meal.calories;
        stats[dayIndex]['protein'] = (stats[dayIndex]['protein'] as int) + meal.protein;
        stats[dayIndex]['carbs'] = (stats[dayIndex]['carbs'] as int) + meal.carbs;
        stats[dayIndex]['fat'] = (stats[dayIndex]['fat'] as int) + meal.fat;
      }
    }

    return stats;
  }
}
