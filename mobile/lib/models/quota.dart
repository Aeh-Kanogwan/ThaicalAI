import 'user.dart';

/// GET /api/v1/scan/quota → { used, limit, resetAt, tier }
/// Also embedded in POST /scan response as `quota`.
class Quota {
  final int used;
  final int limit;
  final DateTime? resetAt;
  final UserTier tier;

  const Quota({
    required this.used,
    required this.limit,
    this.resetAt,
    this.tier = UserTier.free,
  });

  int get remaining => (limit - used).clamp(0, limit);
  bool get isExhausted => used >= limit;
  double get fraction => limit == 0 ? 1.0 : (used / limit).clamp(0.0, 1.0);

  factory Quota.fromJson(Map<String, dynamic> json) {
    return Quota(
      used: (json['used'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
      resetAt: json['resetAt'] != null
          ? DateTime.tryParse(json['resetAt'].toString())
          : null,
      tier: UserTier.fromString(json['tier'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'used': used,
        'limit': limit,
        if (resetAt != null) 'resetAt': resetAt!.toIso8601String(),
        'tier': tier.asJson,
      };

  static const Quota demo = Quota(used: 1, limit: 3, tier: UserTier.free);
}
