import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/weight_repository.dart';

final weightRepositoryProvider = Provider((ref) => WeightRepository());

final weightLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repository = ref.watch(weightRepositoryProvider);
  return repository.getWeightLogs();
});

class WeightNotifier extends StateNotifier<AsyncValue<void>> {
  final WeightRepository _repository;
  final Ref _ref;

  WeightNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<void> addWeight(double weightKg, DateTime date) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.addWeightLog(weightKg, date);
      _ref.invalidate(weightLogsProvider);
    });
  }
}

final weightControllerProvider = StateNotifierProvider<WeightNotifier, AsyncValue<void>>((ref) {
  return WeightNotifier(ref.watch(weightRepositoryProvider), ref);
});
