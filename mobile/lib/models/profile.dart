/// Biological sex used in BMR (Mifflin-St Jeor) computation.
enum Sex {
  male,
  female;

  static Sex fromString(String? v) => v == 'female' ? Sex.female : Sex.male;
  String get asJson => name;
  String get label => this == Sex.male ? 'Male' : 'Female';
}

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive;

  static ActivityLevel fromString(String? v) {
    switch (v) {
      case 'light':
        return ActivityLevel.light;
      case 'moderate':
        return ActivityLevel.moderate;
      case 'active':
        return ActivityLevel.active;
      case 'very_active':
        return ActivityLevel.veryActive;
      case 'sedentary':
      default:
        return ActivityLevel.sedentary;
    }
  }

  /// Serialized form expected by API (`very_active`, not `veryActive`).
  String get asJson =>
      this == ActivityLevel.veryActive ? 'very_active' : name;

  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return 'Lightly active';
      case ActivityLevel.moderate:
        return 'Moderately active';
      case ActivityLevel.active:
        return 'Active';
      case ActivityLevel.veryActive:
        return 'Very active';
    }
  }

  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise';
      case ActivityLevel.light:
        return 'Exercise 1–3 days/week';
      case ActivityLevel.moderate:
        return 'Exercise 3–5 days/week';
      case ActivityLevel.active:
        return 'Exercise 6–7 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise / physical job';
    }
  }
}

enum Goal {
  lose,
  maintain,
  gain;

  static Goal fromString(String? v) {
    switch (v) {
      case 'lose':
        return Goal.lose;
      case 'gain':
        return Goal.gain;
      case 'maintain':
      default:
        return Goal.maintain;
    }
  }

  String get asJson => name;

  String get label {
    switch (this) {
      case Goal.lose:
        return 'Lose weight';
      case Goal.maintain:
        return 'Maintain';
      case Goal.gain:
        return 'Gain muscle';
    }
  }
}

/// User profile body for PUT /me/profile.
class Profile {
  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final Goal goal;

  const Profile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      sex: Sex.fromString(json['sex'] as String?),
      age: (json['age'] as num?)?.toInt() ?? 0,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      activityLevel: ActivityLevel.fromString(json['activityLevel'] as String?),
      goal: Goal.fromString(json['goal'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'sex': sex.asJson,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel.asJson,
        'goal': goal.asJson,
      };

  Profile copyWith({
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activityLevel,
    Goal? goal,
  }) =>
      Profile(
        sex: sex ?? this.sex,
        age: age ?? this.age,
        heightCm: heightCm ?? this.heightCm,
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        goal: goal ?? this.goal,
      );
}
