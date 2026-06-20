import '../services/database_service.dart';

class WeightRepository {
  final DatabaseService _db = DatabaseService();

  // Get all weight logs ordered by date
  Future<List<Map<String, dynamic>>> getWeightLogs() async {
    return await _db.query(
      'weight_logs',
      orderBy: 'date ASC',
    );
  }

  // Add weight log
  Future<int> addWeightLog(double weightKg, DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0];
    return await _db.insert('weight_logs', {
      'date': dateStr,
      'weight_kg': weightKg,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Get latest weight
  Future<double?> getLatestWeight() async {
    final result = await _db.query(
      'weight_logs',
      orderBy: 'date DESC',
      // limit: 1, // sqflite query helper doesn't have limit directly in this wrapper, but we can just take first
    );
    
    if (result.isNotEmpty) {
      return result.first['weight_kg'] as double;
    }
    return null;
  }
}
