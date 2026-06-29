import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/database_service.dart';

enum SyncStatus { synced, syncing, error, pending }

class ProfileService {
  static const String _keyName = 'name';
  static const String _keyHeight = 'height';
  static const String _keyWeight = 'weight';
  static const String _keyAge = 'age';
  static const String _keyGender = 'gender';
  static const String _keyGoal = 'goal';
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyLastLogDate = 'last_log_date';
  
  // Onboarding & Profile Keys
  static const String _keyNutritionKnowledge = 'nutrition_knowledge';
  static const String _keyDietHistory = 'diet_history'; // restricted diet
  static const String _keyFoodLabelKnowledge = 'food_label_knowledge';
  static const String _keyTrackingHistory = 'tracking_history';
  static const String _keyMedicalConditions = 'medical_conditions';
  static const String _keyLifestyle = 'lifestyle';

  final ValueNotifier<SyncStatus> syncStatus = ValueNotifier(SyncStatus.synced);

  Future<void> saveUserProfile({
    String? name,
    double? height,
    double? weight,
    int? age,
    String? gender,
    String? goal,
    String? nutritionKnowledge,
    bool? dietHistory,
    String? foodLabelKnowledge,
    String? trackingHistory,
    String? medicalConditions,
    String? lifestyle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString(_keyName, name);
    if (height != null) await prefs.setDouble(_keyHeight, height);
    if (weight != null) await prefs.setDouble(_keyWeight, weight);
    if (age != null) await prefs.setInt(_keyAge, age);
    if (gender != null) await prefs.setString(_keyGender, gender);
    if (goal != null) await prefs.setString(_keyGoal, goal);
    
    // Save optional onboarding data
    if (nutritionKnowledge != null) await prefs.setString(_keyNutritionKnowledge, nutritionKnowledge);
    if (dietHistory != null) await prefs.setBool(_keyDietHistory, dietHistory);
    if (foodLabelKnowledge != null) await prefs.setString(_keyFoodLabelKnowledge, foodLabelKnowledge);
    if (trackingHistory != null) await prefs.setString(_keyTrackingHistory, trackingHistory);
    if (medicalConditions != null) await prefs.setString(_keyMedicalConditions, medicalConditions);
    if (lifestyle != null) await prefs.setString(_keyLifestyle, lifestyle);

    await prefs.setBool(_keyOnboardingComplete, true);
    await prefs.setBool(_keyIsLoggedIn, true);
    debugPrint('DEBUG: User profile saved. Onboarding complete: true');
    
    // Attempt Cloud Sync
    try {
      await syncProfile();
    } catch (e) {
      debugPrint('DEBUG: Cloud sync failed: $e');
    }
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getBool(_keyOnboardingComplete) ?? false;
    debugPrint('DEBUG: Checking onboarding status: $result');
    return result;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> setLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  Future<void> logout() async {
    await AuthService().signOut();
    await setLoginStatus(false);
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName) ?? 'User',
      'height': prefs.containsKey(_keyHeight) ? prefs.getDouble(_keyHeight) : null,
      'weight': prefs.containsKey(_keyWeight) ? prefs.getDouble(_keyWeight) : null,
      'age': prefs.containsKey(_keyAge) ? prefs.getInt(_keyAge) : null,
      'gender': prefs.getString(_keyGender) ?? 'male', // Default gender is okay for now, or make null too
      'goal': prefs.getString(_keyGoal) ?? 'maintain',
      'nutrition_knowledge': prefs.getString(_keyNutritionKnowledge),
      'diet_history': prefs.getBool(_keyDietHistory),
      'food_label_knowledge': prefs.getString(_keyFoodLabelKnowledge),
      'tracking_history': prefs.getString(_keyTrackingHistory),
      'medical_conditions': prefs.getString(_keyMedicalConditions),
      'lifestyle': prefs.getString(_keyLifestyle),
    };
  }

  Future<void> resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> clearProfile() async {
    await resetApp();
  }

  Future<void> deleteUserData() async {
    await DatabaseService().clearAllData();
    await resetApp();
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Cloud deletion signout error: $e');
    }
  }

  // --- Cloud Sync Logic ---
  Future<void> syncProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    syncStatus.value = SyncStatus.syncing;
    try {
      final profileData = await getUserProfile();
      profileData['id'] = user.id;
      profileData['updated_at'] = DateTime.now().toIso8601String();

      await Supabase.instance.client
          .from('profiles')
          .upsert(profileData);
      
      syncStatus.value = SyncStatus.synced;
      debugPrint('DEBUG: Profile synced to cloud for user ${user.id}');
    } catch (e) {
      syncStatus.value = SyncStatus.error;
      debugPrint('DEBUG: Sync failed: $e');
    }
  }

  Future<void> fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      
      // Update Local Prefs
      saveUserProfile(
        name: data['name'],
        height: (data['height'] as num?)?.toDouble(),
        weight: (data['weight'] as num?)?.toDouble(),
        age: (data['age'] as num?)?.toInt(),
        gender: data['gender'],
        goal: data['goal'],
        nutritionKnowledge: data['nutrition_knowledge'],
        dietHistory: data['diet_history'],
        foodLabelKnowledge: data['food_label_knowledge'],
        trackingHistory: data['tracking_history'],
        medicalConditions: data['medical_conditions'],
        lifestyle: data['lifestyle'],
      );
      debugPrint('DEBUG: Profile fetched from cloud');
    } catch (e) {
      debugPrint('DEBUG: Fetch profile failed (maybe new user?): $e');
    }
  }

  // --- Streak Logic ---
  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogStr = prefs.getString(_keyLastLogDate);
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    if (lastLogStr == todayStr) return; // Already logged today

    int currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
    
    if (lastLogStr != null) {
      final lastLogDate = DateTime.parse(lastLogStr);
      final difference = now.difference(lastLogDate).inDays;

      if (difference == 1) {
        currentStreak++;
      } else if (difference > 1) {
        currentStreak = 1; // Reset streak
      }
    } else {
      currentStreak = 1; // First log
    }

    await prefs.setInt(_keyCurrentStreak, currentStreak);
    await prefs.setString(_keyLastLogDate, todayStr);
  }

  Future<int> getCurrentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrentStreak) ?? 0;
  }

  Future<Map<String, int>> calculateDailyTargets() async {
    final prefs = await SharedPreferences.getInstance();
    final height = prefs.getDouble(_keyHeight) ?? 170;
    final weight = prefs.getDouble(_keyWeight) ?? 70;
    final age = prefs.getInt(_keyAge) ?? 25;
    final gender = prefs.getString(_keyGender) ?? 'male';
    final goal = prefs.getString(_keyGoal) ?? 'maintain';

    // Normalize Height to CM
    double heightCm = height;
    if (height < 3.0) {
      heightCm = height * 100;
    } else if (height >= 3.0 && height < 9.0) {
      heightCm = height * 30.48;
    } else if (height >= 9.0 && height < 100.0) {
       heightCm = height * 2.54;
    }
    
    // Mifflin-St Jeor Formula
    double bmr = (10 * weight) + (6.25 * heightCm) - (5 * age);
    bmr += (gender == 'male' ? 5 : -161);

    // Assume Moderate Activity (1.55) for MVP or use lifestyle
    double activityMultiplier = 1.55; 
    final lifestyle = prefs.getString(_keyLifestyle);
    if (lifestyle != null) {
      if (lifestyle.contains('Sedentary')) {
        activityMultiplier = 1.2;
      } else if (lifestyle.contains('Light')) {
        activityMultiplier = 1.375;
      } else if (lifestyle.contains('Moderate')) {
        activityMultiplier = 1.55;
      } else if (lifestyle.contains('Active')) {
        activityMultiplier = 1.725;
      }
    }

    double tdee = bmr * activityMultiplier;

    int targetCalories;
    switch (goal) {
      case 'loss':
      case 'loss_normal':
        targetCalories = (tdee - 500).round();
        break;
      case 'loss_slow':
        targetCalories = (tdee - 250).round();
        break;
      case 'loss_fast':
        targetCalories = (tdee - 750).round();
        break;
      case 'gain':
        targetCalories = (tdee + 300).round();
        break;
      default:
        targetCalories = tdee.round();
    }
    
    // Safety Floor: Never recommend below 1200 kcal without medical supervision
    if (targetCalories < 1200) {
      targetCalories = 1200;
    }

    // Macro Split (40/30/30)
    return {
      'calories': targetCalories,
      'protein': ((targetCalories * 0.30) / 4).round(),
      'carbs': ((targetCalories * 0.40) / 4).round(),
      'fat': ((targetCalories * 0.30) / 9).round(),
    };
  }

  double calculateBMR(Map<String, dynamic> profile) {
    // Mifflin-St Jeor Equation
    final weight = (profile['weight'] as num?)?.toDouble() ?? 70.0;
    final height = (profile['height'] as num?)?.toDouble() ?? 170.0;
    final age = (profile['age'] as num?)?.toInt() ?? 25;
    final gender = profile['gender'] as String? ?? 'Male';

    double bmr = (10 * weight) + (6.25 * height) - (5 * age);
    if (gender == 'Male') {
      bmr += 5;
    } else {
      bmr -= 161;
    }
    return bmr;
  }
}
