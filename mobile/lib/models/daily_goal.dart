/// `dailyGoal`: { calories, proteinG, carbsG, fatG, bmr, tdee }
class DailyGoal {
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double bmr;
  final double tdee;

  const DailyGoal({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.bmr,
    required this.tdee,
  });

  factory DailyGoal.fromJson(Map<String, dynamic> json) {
    return DailyGoal(
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0,
      bmr: (json['bmr'] as num?)?.toDouble() ?? 0,
      tdee: (json['tdee'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'bmr': bmr,
        'tdee': tdee,
      };

  /// Fallback used in demo mode before a profile is computed server-side.
  static const DailyGoal demo = DailyGoal(
    calories: 2000,
    proteinG: 150,
    carbsG: 200,
    fatG: 67,
    bmr: 1550,
    tdee: 2000,
  );
}
