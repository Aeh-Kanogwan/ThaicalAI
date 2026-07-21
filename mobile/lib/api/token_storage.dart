import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';

/// Thin wrapper around flutter_secure_storage for the JWT.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: AppConfig.tokenKey);

  Future<void> write(String token) =>
      _storage.write(key: AppConfig.tokenKey, value: token);

  Future<void> clear() => _storage.delete(key: AppConfig.tokenKey);
}
