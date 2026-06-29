import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/secrets.dart';
import '../utils/image_resizer.dart';

class AIService {
  static const String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent';
  
  static const String _systemPrompt = '''
ROLE: You are NutriVision, an elite AI Nutritional Auditor. Your goal is to rigorously audit the meal in the image for hidden calories, cooking oils, and volumetric portion sizes with 98% accuracy.

ANALYSIS PROTOCOL:
1. Plate Calibration: Identify standard objects to estimate scale (e.g., "Standard 10-inch dinner plate").
2. Depth & Volume: Estimate the Z-axis height. Is the rice a flat layer or a mound?
3. "Hidden Calorie" Audit: Look for "sheen" or "gloss" on food. High gloss = Oil/Butter usage. Assume restaurant meals contain 20% more fat than homemade unless specified.

OUTPUT SCHEMA (Return ONLY raw JSON):
{
  "summary": {
    "title": "Short descriptive meal title",
    "total_calories": 0,
    "confidence_score": 0.95,
    "health_grade": "A-F grade based on micronutrient density"
  },
  "macros": {
    "protein_g": 0, "carbs_g": 0, "fats_g": 0
  },
  "micros_focus": {
    "sugar_g": 0, "fiber_g": 0, "sodium_mg": 0
  },
  "items": [
    {
      "name": "Ingredient Name",
      "detected_state": "e.g., Grilled, skin-on",
      "portion_visual_cue": "e.g., Palm-sized, approx 6oz",
      "calories": 0,
      "macros": { "p": 0, "c": 0, "f": 0 },
      "box_2d": [x, y] // Normalized coordinates (0-100) for AR dot placement
    }
  ],
  "hidden_calorie_check": {
    "detected": boolean,
    "reason": "String explaining if oil/butter was detected via visual sheen",
    "adjustment_calories": 0
  }
}
''';

  Future<Map<String, dynamic>> analyzeFoodImage(String imagePath, {String? userHint}) async {
    try {
      if (Secrets.geminiApiKey.isEmpty) {
        throw Exception('Gemini API Key is missing. Please update lib/core/constants/secrets.dart.');
      }

      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Image file not found at $imagePath');
      }

      // Resize image for optimization
      String finalImagePath = imagePath;
      try {
        finalImagePath = await ImageResizer.resizeImage(imagePath);
      } catch (e) {
        debugPrint('Resize warning: $e');
      }
      
      final imageBytes = await File(finalImagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$_geminiUrl?key=${Secrets.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": "$_systemPrompt\n\nAnalyze this meal.${userHint != null && userHint.isNotEmpty ? '\nUser note/description: $userHint' : ''}"
                },
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json",
            "response_schema": {
              "type": "OBJECT",
              "properties": {
                "summary": {
                  "type": "OBJECT",
                  "properties": {
                    "title": {"type": "STRING"},
                    "total_calories": {"type": "INTEGER"},
                    "confidence_score": {"type": "NUMBER"},
                    "health_grade": {"type": "STRING"}
                  },
                  "required": ["title", "total_calories", "confidence_score", "health_grade"]
                },
                "macros": {
                  "type": "OBJECT",
                  "properties": {
                    "protein_g": {"type": "INTEGER"},
                    "carbs_g": {"type": "INTEGER"},
                    "fats_g": {"type": "INTEGER"}
                  },
                  "required": ["protein_g", "carbs_g", "fats_g"]
                },
                "micros_focus": {
                  "type": "OBJECT",
                  "properties": {
                    "sugar_g": {"type": "INTEGER"},
                    "fiber_g": {"type": "INTEGER"},
                    "sodium_mg": {"type": "INTEGER"}
                  },
                  "required": ["sugar_g", "fiber_g", "sodium_mg"]
                },
                "items": {
                  "type": "ARRAY",
                  "items": {
                    "type": "OBJECT",
                    "properties": {
                      "name": {"type": "STRING"},
                      "detected_state": {"type": "STRING"},
                      "portion_visual_cue": {"type": "STRING"},
                      "calories": {"type": "INTEGER"},
                      "macros": {
                        "type": "OBJECT",
                        "properties": {
                          "p": {"type": "INTEGER"},
                          "c": {"type": "INTEGER"},
                          "f": {"type": "INTEGER"}
                        },
                        "required": ["p", "c", "f"]
                      },
                      "box_2d": {
                        "type": "ARRAY",
                        "items": {"type": "INTEGER"}
                      }
                    },
                    "required": ["name", "detected_state", "portion_visual_cue", "calories", "macros"]
                  }
                },
                "hidden_calorie_check": {
                  "type": "OBJECT",
                  "properties": {
                    "detected": {"type": "BOOLEAN"},
                    "reason": {"type": "STRING"},
                    "adjustment_calories": {"type": "INTEGER"}
                  },
                  "required": ["detected", "reason", "adjustment_calories"]
                }
              },
              "required": [
                "summary",
                "macros",
                "micros_focus",
                "items",
                "hidden_calorie_check"
              ]
            }
          }
        }),
      );

      if (kDebugMode) {
        debugPrint('DEBUG: Gemini Status Code: ${response.statusCode}');
        debugPrint('DEBUG: Gemini Response: ${response.body}');
      }

      if (response.statusCode != 200) {
        throw Exception('Gemini API Error: ${response.statusCode} - ${response.body}');
      }

      final data = jsonDecode(response.body);
      final content = data['candidates']?[0]['content']?['parts']?[0]['text']?.toString();

      if (content == null) {
        throw Exception('Empty response from Gemini AI');
      }

      return jsonDecode(content.trim());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AI Analysis Error: $e');
      }
      throw Exception('Failed to analyze food: $e');
    }
  }

  Future<Map<String, dynamic>> getNutritionFromText(String foodName, String quantity) async {
    try {
      if (Secrets.geminiApiKey.isEmpty) {
         throw Exception('Gemini API Key is missing');
      }

      final prompt = '''
      Estimate nutritional info for "$quantity" of "$foodName".
      Return ONLY raw JSON with no markdown formatting.
      Schema:
      {
        "calories": 0,
        "protein_g": 0,
        "carbs_g": 0,
        "fats_g": 0
      }
      ''';

      final response = await http.post(
        Uri.parse('$_geminiUrl?key=${Secrets.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "response_mime_type": "application/json"
          }
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gemini API Error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final content = data['candidates']?[0]['content']?['parts']?[0]['text']?.toString();

      if (content == null) throw Exception('Empty response');

      final cleanJson = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(cleanJson);
    } catch (e) {
      debugPrint('AI Text Analysis Error: $e');
      throw Exception('Failed to estimate nutrition: $e');
    }
  }

  Future<String> getHealthTip({
    required int caloriesConsumed,
    required int calorieGoal,
    required int proteinConsumed,
    required int carbsConsumed,
    required int fatConsumed,
  }) async {
    try {
       if (Secrets.geminiApiKey.isEmpty) return "Keep going!";

      final prompt = '''
      User Stats:
      - Calories: $caloriesConsumed / $calorieGoal
      - Protein: ${proteinConsumed}g
      - Carbs: ${carbsConsumed}g
      - Fat: ${fatConsumed}g

      Give a single, short, motivating health tip (max 15 words).
      ''';
      
      final response = await http.post(
        Uri.parse('$_geminiUrl?key=${Secrets.geminiApiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]['content']?['parts']?[0]['text']?.toString() ?? "Stay consistent!";
      }
      return "Stay healthy!";
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AI Tip Error: $e');
      }
      return "Eat more whole foods!";
    }
  }
}
