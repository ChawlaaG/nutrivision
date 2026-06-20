import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class LocalFoodService {
  static final LocalFoodService _instance = LocalFoodService._internal();
  List<Map<String, dynamic>> _foods = [];

  factory LocalFoodService() => _instance;

  LocalFoodService._internal();

  Future<void> loadDatabase() async {
    if (_foods.isNotEmpty) return;

    try {
      final String response = await rootBundle.loadString('assets/data/food_db.json');
      final List<dynamic> data = json.decode(response);
      _foods = data.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading food database: $e');
    }
  }

  List<Map<String, dynamic>> searchFoods(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return _foods.where((food) {
      final name = food['name'].toString().toLowerCase();
      return name.contains(lowerQuery);
    }).toList();
  }

  List<Map<String, dynamic>> getAllFoods() {
    return _foods;
  }
}
