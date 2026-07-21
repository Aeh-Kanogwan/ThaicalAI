import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../config.dart';
import '../models/models.dart';
import 'auth_state.dart';
import 'providers.dart';

/// Loads the AI scan quota (GET /scan/quota). Falls back to a tier-based
/// default when offline in demo mode.
final quotaProvider = FutureProvider.autoDispose<Quota>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    return await api.getQuota();
  } on ApiException catch (e) {
    if (AppConfig.demoFallbackEnabled && e.isNetwork) {
      final tier = ref.read(authControllerProvider).user?.tier ?? UserTier.free;
      return Quota(
        used: 1,
        limit: tier.isVip
            ? AppConfig.vipScanDailyLimit
            : AppConfig.freeScanLifetimeLimit,
        tier: tier,
      );
    }
    rethrow;
  }
});
