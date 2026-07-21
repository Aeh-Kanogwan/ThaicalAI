/// App-wide configuration constants for CalThai AI.
///
/// NOTE ON BASE URL:
/// - iOS simulator / desktop / web can reach the host machine at `localhost`.
/// - Android emulator CANNOT use `localhost` — it must use the special
///   loopback alias `10.0.2.2` to reach the host machine.
/// We resolve this at runtime via [AppConfig.apiBaseUrl].
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  AppConfig._();

  // ---- API ----
  /// Host-machine base URL for iOS simulator / desktop.
  static const String _devBaseLocalhost = 'http://localhost:4000';

  /// Android emulator loopback to host machine.
  static const String _devBaseAndroidEmu = 'http://10.0.2.2:4000';

  /// API version path prefix (matches docs/API_CONTRACT.md).
  static const String apiPrefix = '/api/v1';

  /// Resolved base URL (without the version prefix).
  static String get baseUrl {
    if (kIsWeb) return _devBaseLocalhost;
    try {
      if (Platform.isAndroid) return _devBaseAndroidEmu;
    } catch (_) {
      // Platform not available (e.g. tests) — fall through.
    }
    return _devBaseLocalhost;
  }

  /// Full API root, e.g. http://10.0.2.2:4000/api/v1
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// Network timeouts.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ---- Demo mode ----
  /// When true, screens fall back to mock data if the API is unreachable so
  /// the UI is fully explorable before the backend is running.
  /// Real API calls are always attempted first.
  static const bool demoFallbackEnabled = true;

  // ---- Pricing (THB) ----
  static const int monthlyPriceThb = 99;
  static const int yearlyPriceThb = 890;
  static const int freeTrialDays = 7;

  // ---- Quota (mirrors API contract) ----
  static const int freeScanLifetimeLimit = 3; // free: 3 total lifetime trial
  static const int vipScanDailyLimit = 10; // vip: 10/day

  // ---- Secure storage keys ----
  static const String tokenKey = 'calthai_jwt';
  static const String userCacheKey = 'calthai_user';
}
