import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../services/local_food_service.dart';
import '../services/open_food_facts_service.dart';

class FoodRepository {
  final DatabaseService _db = DatabaseService();
  final LocalFoodService _localFoodService = LocalFoodService();
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();

  // Search local JSON, custom SQLite foods, and OpenFoodFacts API
  Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    if (query.isEmpty) return [];

    // 1. Search Local JSON (Fastest)
    final localResults = _localFoodService.searchFoods(query);

    // 2. Search Custom Foods (SQLite)
    final customResults = await _db.query(
      'custom_foods',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );

    // 3. Search OpenFoodFacts API (Network)
    List<Map<String, dynamic>> apiResults = [];
    try {
      apiResults = await _openFoodFactsService.searchProducts(query);
    } catch (e) {
      debugPrint("API Search Failed: $e");
    }

    // 4. Combine Results
    final List<Map<String, dynamic>> combined = [];

    for (var food in localResults) {
      final Map<String, dynamic> item = Map.from(food);
      item['source'] = 'local';
      combined.add(item);
    }

    for (var food in customResults) {
      final Map<String, dynamic> item = Map.from(food);
      item['source'] = 'custom';
      combined.add(item);
    }
    
    // Add API results (avoiding duplicates by name if possible? For now just append)
    for (var food in apiResults) {
      final Map<String, dynamic> item = Map.from(food);
      item['source'] = 'api';
      combined.add(item);
    }

    return combined;
  }

  // Get product by barcode (Cache -> API -> Cache)
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    // 1. Check Cache
    final cached = await _db.query(
      'barcode_cache',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (cached.isNotEmpty) {
      try {
        final dataStr = cached.first['data'] as String;
        return jsonDecode(dataStr) as Map<String, dynamic>;
      } catch (e) {
        // Cache read failed, fallback to API
      }
    }
    
    // 2. Call API
    final product = await _openFoodFactsService.getProductByBarcode(barcode);
    
    if (product != null) {
      // 3. Save to Cache
      await _db.insert('barcode_cache', {
        'barcode': barcode,
        'data': jsonEncode(product),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
    
    return product;
  }

  // Add a new custom food
  Future<int> addCustomFood({
    required String name,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    String servingSize = '1 serving',
  }) async {
    return await _db.insert('custom_foods', {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'serving_size': servingSize,
    });
  }

  // Delete a custom food
  Future<int> deleteCustomFood(int id) async {
    return await _db.delete('custom_foods', 'id = ?', [id]);
  }
}
