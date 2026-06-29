import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();

  Future<bool> requestPermissions() async {
    // Request Activity Recognition (Android)
    await Permission.activityRecognition.request();

    final types = [
      HealthDataType.ACTIVE_ENERGY_BURNED,
    ];

    // Check if we have permissions
    bool? hasPermissions = await _health.hasPermissions(types);

    if (hasPermissions == false) {
      try {
        hasPermissions = await _health.requestAuthorization(types);
      } catch (e) {
        debugPrint("Health Authorization Error: $e");
        return false;
      }
    }
    return hasPermissions ?? false;
  }

  Future<int> getTodaySteps() async {
    return 0;
  }

  Future<int> getTodayBurnedCalories() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      // Fetch Active Energy Burned
      final healthData = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      double totalCalories = 0;
      for (var data in healthData) {
        // Health package returns value as double
        // Ensure we handle the value correctly based on platform/unit
        // Usually it's in Kilocalories
        totalCalories += (data.value as NumericHealthValue).numericValue;
      }
      return totalCalories.round();
    } catch (e) {
      debugPrint("Error fetching calories: $e");
      return 0;
    }
  }
}
