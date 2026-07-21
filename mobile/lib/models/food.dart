/// `Food`: { id, nameTh, nameEn, calories, protein, fat, carbs, sodium,
///            servingSize, isVerified }
class Food {
  final String id;
  final String nameTh;
  final String? nameEn;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final double? sodium;
  final String servingSize;
  final bool isVerified;

  const Food({
    required this.id,
    required this.nameTh,
    this.nameEn,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.sodium,
    required this.servingSize,
    required this.isVerified,
  });

  /// Localized display name — prefer Thai, fall back to English.
  String get displayName => nameTh.isNotEmpty ? nameTh : (nameEn ?? '');

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id']?.toString() ?? '',
      nameTh: json['nameTh'] as String? ?? '',
      nameEn: json['nameEn'] as String?,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      sodium: (json['sodium'] as num?)?.toDouble(),
      servingSize: json['servingSize'] as String? ?? '1 จาน',
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameTh': nameTh,
        'nameEn': nameEn,
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'sodium': sodium,
        'servingSize': servingSize,
        'isVerified': isVerified,
      };
}
