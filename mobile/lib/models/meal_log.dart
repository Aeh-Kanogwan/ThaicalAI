/// Meal categories used to group the daily timeline.
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  static MealType fromString(String? v) {
    switch (v) {
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'snack':
        return MealType.snack;
      case 'breakfast':
      default:
        return MealType.breakfast;
    }
  }

  String get asJson => name;

  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }
}

/// `MealLog`: { id, foodId, name, mealType, grams, calories, protein,
///              carbs, fat, sodium, loggedAt }
class MealLog {
  final String id;
  final String? foodId;
  final String name;
  final MealType mealType;
  final double grams;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? sodium;
  final DateTime loggedAt;

  const MealLog({
    required this.id,
    this.foodId,
    required this.name,
    required this.mealType,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sodium,
    required this.loggedAt,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id']?.toString() ?? '',
      foodId: json['foodId']?.toString(),
      name: json['name'] as String? ?? '',
      mealType: MealType.fromString(json['mealType'] as String?),
      grams: (json['grams'] as num?)?.toDouble() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      sodium: (json['sodium'] as num?)?.toDouble(),
      loggedAt: DateTime.tryParse(json['loggedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodId': foodId,
        'name': name,
        'mealType': mealType.asJson,
        'grams': grams,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'sodium': sodium,
        'loggedAt': loggedAt.toIso8601String(),
      };
}

/// Request body for POST /api/v1/logs.
class CreateLogRequest {
  final String? foodId;
  final String? customName;
  final MealType mealType;
  final double grams;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? sodium;
  final String? scanId;
  final DateTime? loggedAt;

  const CreateLogRequest({
    this.foodId,
    this.customName,
    required this.mealType,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sodium,
    this.scanId,
    this.loggedAt,
  });

  Map<String, dynamic> toJson() => {
        'foodId': foodId,
        'customName': customName,
        'mealType': mealType.asJson,
        'grams': grams,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'sodium': sodium,
        'scanId': scanId,
        if (loggedAt != null) 'loggedAt': loggedAt!.toIso8601String(),
      };
}

/// summary block from GET /logs.
class DailySummary {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sodium;
  final int target;

  const DailySummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sodium,
    required this.target,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'sodium': sodium,
        'target': target,
      };

  static const DailySummary empty = DailySummary(
    calories: 0,
    protein: 0,
    carbs: 0,
    fat: 0,
    sodium: 0,
    target: 2000,
  );
}

/// Full GET /logs?date= response.
class DayLog {
  final String date;
  final DailySummary summary;
  final List<MealLog> logs;

  const DayLog({
    required this.date,
    required this.summary,
    required this.logs,
  });

  factory DayLog.fromJson(Map<String, dynamic> json) {
    return DayLog(
      date: json['date'] as String? ?? '',
      summary: DailySummary.fromJson(
          (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {}),
      logs: ((json['logs'] as List?) ?? const [])
          .map((e) => MealLog.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  /// Group logs by meal type in a stable meal order.
  Map<MealType, List<MealLog>> groupedByMeal() {
    final map = <MealType, List<MealLog>>{
      for (final t in MealType.values) t: <MealLog>[],
    };
    for (final log in logs) {
      map[log.mealType]!.add(log);
    }
    return map;
  }
}
