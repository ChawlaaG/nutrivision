import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/water_repository.dart';

final waterRepositoryProvider = Provider((ref) => WaterRepository());

final dailyWaterProvider = FutureProvider.family<int, DateTime>((ref, date) async {
  final repository = ref.watch(waterRepositoryProvider);
  return repository.getWaterIntake(date);
});

class WaterNotifier extends StateNotifier<AsyncValue<void>> {
  final WaterRepository _repository;
  final Ref _ref;

  WaterNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addWater(int amountMl, DateTime date) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addWaterLog(amountMl, date);
      // Invalidate the provider to trigger a refresh
      _ref.invalidate(dailyWaterProvider(date));
    });
  }
}

final waterControllerProvider = StateNotifierProvider<WaterNotifier, AsyncValue<void>>((ref) {
  return WaterNotifier(ref.watch(waterRepositoryProvider), ref);
});
