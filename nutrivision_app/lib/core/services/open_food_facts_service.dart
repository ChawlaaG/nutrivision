import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org';

  /// Search for products by name
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
        '$_baseUrl/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1&page_size=20');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'NutriVision/1.0 (support@nutrivision.ai) - Android',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'] as List<dynamic>? ?? [];

        return products.map((product) => _mapProductToAppModel(product)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OpenFoodFacts Search Error: $e');
      }
      return [];
    }
  }

  /// Get a single product by barcode
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final url = Uri.parse('$_baseUrl/api/v0/product/$barcode.json');

    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'NutriVision/1.0 (support@nutrivision.ai) - Android',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          return _mapProductToAppModel(data['product']);
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OpenFoodFacts Barcode Error: $e');
      }
      return null;
    }
  }

  /// Map API response to our app's internal data structure
  Map<String, dynamic> _mapProductToAppModel(Map<String, dynamic> product) {
    final nutriments = product['nutriments'] ?? {};
    
    // Helper to safely get double values
    double getVal(String key) {
      final val = nutriments[key];
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return {
      'name': product['product_name'] ?? 'Unknown Product',
      'brand': product['brands'] ?? '',
      'calories': getVal('energy-kcal_100g').round(),
      'protein': getVal('proteins_100g'),
      'carbs': getVal('carbohydrates_100g'),
      'fat': getVal('fat_100g'),
      'unit': '100g', // API standardizes on 100g/100ml
      'image_url': product['image_front_url'],
    };
  }
}
