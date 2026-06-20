import '../services/database_service.dart';

class WaterRepository {
  final DatabaseService _db = DatabaseService();

  // Get water intake for a specific date (YYYY-MM-DD)
  Future<int> getWaterIntake(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await _db.query(
      'water_logs',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    int total = 0;
    for (var row in result) {
      total += (row['amount_ml'] as int);
    }
    return total;
  }

  // Add water log
  Future<int> addWaterLog(int amountMl, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await _db.insert('water_logs', {
      'date': dateStr,
      'amount_ml': amountMl,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
