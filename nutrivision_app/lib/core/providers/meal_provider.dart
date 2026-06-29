import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/meal_repository.dart';
import '../models/meal.dart';
import '../services/streak_service.dart';
import '../services/review_service.dart';

final mealRepositoryProvider = Provider((ref) => MealRepository());

final dailyMealsProvider = FutureProvider.family<List<Meal>, DateTime>((ref, date) async {
  final repository = ref.watch(mealRepositoryProvider);
  return repository.getMealsForDate(date);
});

final dailyMacrosProvider = FutureProvider.family<Map<String, int>, DateTime>((ref, date) async {
  final repository = ref.watch(mealRepositoryProvider);
  return repository.getDailyMacros(date);
});

final weeklyStatsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(mealRepositoryProvider);
  return repository.getWeeklyStats();
});

class MealNotifier extends StateNotifier<AsyncValue<void>> {
  final MealRepository _repository;

  MealNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> addMeal(Meal meal) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addMeal(meal);
      await StreakService().updateStreak();
      await ReviewService().requestReviewIfAppropriate();
    });
  }

  Future<void> deleteMeal(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteMeal(id));
  }

  Future<void> updateMeal(Meal meal) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateMeal(meal);
      // Recalculate streak or other stats if necessary, though update usually doesn't affect streak count unless date changes
      // For now, we assume date might change, so let's update streak just in case, or at least refresh the list
    });
  }
}

final mealControllerProvider = StateNotifierProvider<MealNotifier, AsyncValue<void>>((ref) {
  return MealNotifier(ref.watch(mealRepositoryProvider));
});
