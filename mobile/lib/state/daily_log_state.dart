import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../config.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import 'providers.dart';

String _todayString() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Currently selected day (YYYY-MM-DD) for the dashboard/history.
final selectedDateProvider = StateProvider<String>((ref) => _todayString());

/// Loads the day log (summary + meal logs) for [selectedDateProvider].
/// Falls back to mock data when the backend is unreachable in demo mode.
final dailyLogProvider = FutureProvider.autoDispose<DayLog>((ref) async {
  final api = ref.watch(apiClientProvider);
  final date = ref.watch(selectedDateProvider);
  try {
    return await api.getDayLog(date);
  } on ApiException catch (e) {
    if (AppConfig.demoFallbackEnabled && e.isNetwork) {
      return MockData.demoDayLog(date);
    }
    rethrow;
  }
});

/// Imperative helpers for mutating logs then refreshing the day view.
class LogActions {
  LogActions(this._ref);
  final Ref _ref;

  Future<void> addLog(CreateLogRequest req) async {
    final api = _ref.read(apiClientProvider);
    try {
      await api.createLog(req);
    } on ApiException catch (e) {
      if (!(AppConfig.demoFallbackEnabled && e.isNetwork)) rethrow;
      // Demo: silently accept; the mock day log stands in.
    }
    _ref.invalidate(dailyLogProvider);
  }

  Future<void> deleteLog(String id) async {
    final api = _ref.read(apiClientProvider);
    try {
      await api.deleteLog(id);
    } on ApiException catch (e) {
      if (!(AppConfig.demoFallbackEnabled && e.isNetwork)) rethrow;
    }
    _ref.invalidate(dailyLogProvider);
  }
}

final logActionsProvider = Provider<LogActions>((ref) => LogActions(ref));
