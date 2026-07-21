/// Weight tracker entry.
/// GET /weight → { entries: [{ id, weightKg, photoUrl, loggedAt }] }
class WeightEntry {
  final String id;
  final double weightKg;
  final String? photoUrl;
  final DateTime loggedAt;

  const WeightEntry({
    required this.id,
    required this.weightKg,
    this.photoUrl,
    required this.loggedAt,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id']?.toString() ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      photoUrl: json['photoUrl'] as String?,
      loggedAt: DateTime.tryParse(json['loggedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'weightKg': weightKg,
        'photoUrl': photoUrl,
        'loggedAt': loggedAt.toIso8601String(),
      };
}
