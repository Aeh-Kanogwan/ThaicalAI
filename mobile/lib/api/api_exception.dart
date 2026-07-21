/// Normalized API error surfaced to the UI layer.
///
/// Backend error shape: `{ "error": { "code": string, "message": string } }`.
class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;

  const ApiException({
    this.statusCode,
    required this.code,
    required this.message,
  });

  /// True when the scan quota is used up (HTTP 402 / QUOTA_EXCEEDED).
  bool get isQuotaExceeded =>
      statusCode == 402 || code == 'QUOTA_EXCEEDED';

  bool get isUnauthorized => statusCode == 401;

  bool get isNetwork => code == 'NETWORK';

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
