import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../config.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import 'providers.dart';

/// Loads weight entries for the last ~90 days for the history chart.
final weightEntriesProvider =
    FutureProvider.autoDispose<List<WeightEntry>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final now = DateTime.now();
  try {
    final entries = await api.getWeightEntries(
      from: now.subtract(const Duration(days: 90)),
      to: now,
    );
    return entries;
  } on ApiException catch (e) {
    if (AppConfig.demoFallbackEnabled && e.isNetwork) {
      return MockData.demoWeights;
    }
    rethrow;
  }
});

/// Logs a new weight then refreshes the chart.
final weightActionsProvider = Provider<WeightActions>((ref) => WeightActions(ref));

class WeightActions {
  WeightActions(this._ref);
  final Ref _ref;

  Future<void> add(double weightKg) async {
    final api = _ref.read(apiClientProvider);
    try {
      await api.logWeight(weightKg);
    } on ApiException catch (e) {
      if (!(AppConfig.demoFallbackEnabled && e.isNetwork)) rethrow;
    }
    _ref.invalidate(weightEntriesProvider);
  }
}
