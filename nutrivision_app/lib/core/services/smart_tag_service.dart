import 'package:flutter/material.dart';

class SmartTag {
  final String label;
  final IconData icon;
  final Color color;
  final String description;

  SmartTag({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class SmartTagService {
  
  // Singleton pattern
  static final SmartTagService _instance = SmartTagService._internal();
  factory SmartTagService() => _instance;
  SmartTagService._internal();

  /// Analyze food item against user profile to generate relevant tags
  List<SmartTag> analyzeFood({
    required Map<String, dynamic> foodItem,
    required Map<String, dynamic> userProfile,
  }) {
    final List<SmartTag> tags = [];

    // Extract Profile Data
    final String medicalConditions = (userProfile['medical_conditions'] ?? '').toString().toLowerCase();
    final String lifestyle = (userProfile['lifestyle'] ?? '').toString().toLowerCase();

    // Extract Food Data (Standardized to 100g roughly from OpenFoodFacts service)
    final double calories = (foodItem['calories'] as num?)?.toDouble() ?? 0;
    final double sugar = (foodItem['sugar'] as num?)?.toDouble() ?? 0;
    final double sodium = (foodItem['sodium'] as num?)?.toDouble() ?? 0;
    final double protein = (foodItem['protein'] as num?)?.toDouble() ?? 0;
    final double carbs = (foodItem['carbs'] as num?)?.toDouble() ?? 0;

    // --- 1. Medical Condition Checks ---

    // Diabetes Check
    if (medicalConditions.contains('diabetes')) {
      if (sugar > 10 || carbs > 20) {
        tags.add(SmartTag(
          label: 'High Sugar',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          description: 'This item has significant sugar/carbs. Monitor intake.',
        ));
      } else if (sugar < 2 && carbs < 5) {
        tags.add(SmartTag(
          label: 'Diabetes Friendly',
          icon: Icons.check_circle_outline,
          color: Colors.green,
          description: 'Low in sugar and carbs.',
        ));
      }
    }

    // Hypertension / Heart Health
    if (medicalConditions.contains('hypertension') || medicalConditions.contains('heart')) {
      if (sodium > 400) { // arbitrary threshold, refine as needed
        tags.add(SmartTag(
          label: 'High Sodium',
          icon: Icons.water_drop_outlined,
          color: Colors.redAccent,
          description: 'High sodium content may affect blood pressure.',
        ));
      }
    }

    // --- 2. Lifestyle Checks ---

    // Active Lifestyle
    if (lifestyle.contains('active')) {
      if (protein > 15) {
        tags.add(SmartTag(
          label: 'Protein Boost',
          icon: Icons.fitness_center,
          color: Colors.blueAccent,
          description: 'Great for muscle recovery.',
        ));
      }
    }

    // Sedentary Lifestyle
    if (lifestyle.contains('sedentary')) {
      if (calories > 400) {
        tags.add(SmartTag(
          label: 'Calorie Dense',
          icon: Icons.local_fire_department,
          color: Colors.deepOrange,
          description: 'High energy density. Portion control recommended.',
        ));
      }
    }

    return tags;
  }
}
