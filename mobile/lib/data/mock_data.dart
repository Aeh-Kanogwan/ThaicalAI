import '../models/models.dart';

/// Static placeholder data so every screen renders before the backend exists.
/// Used only when [AppConfig.demoFallbackEnabled] is true and the API is
/// unreachable (see providers). Never used when a real response succeeds.
class MockData {
  MockData._();

  static User get demoUser => User(
        id: 'demo-user',
        email: 'demo@calthai.ai',
        name: 'Ploy',
        tier: UserTier.free,
        createdAt: DateTime(2026, 1, 1),
      );

  static const Profile demoProfile = Profile(
    sex: Sex.female,
    age: 29,
    heightCm: 165,
    weightKg: 58,
    activityLevel: ActivityLevel.moderate,
    goal: Goal.lose,
  );

  static const List<Food> demoFoods = [
    Food(
      id: 'f1',
      nameTh: 'ข้าวผัดกะเพราไก่',
      nameEn: 'Chicken Basil Fried Rice',
      calories: 620,
      protein: 28,
      fat: 22,
      carbs: 78,
      sodium: 1100,
      servingSize: '1 จาน',
      isVerified: true,
    ),
    Food(
      id: 'f2',
      nameTh: 'ต้มยำกุ้ง',
      nameEn: 'Tom Yum Goong',
      calories: 220,
      protein: 18,
      fat: 9,
      carbs: 14,
      sodium: 1400,
      servingSize: '1 ถ้วย',
      isVerified: true,
    ),
    Food(
      id: 'f3',
      nameTh: 'ส้มตำไทย',
      nameEn: 'Papaya Salad',
      calories: 180,
      protein: 5,
      fat: 6,
      carbs: 28,
      sodium: 900,
      servingSize: '1 จาน',
      isVerified: true,
    ),
    Food(
      id: 'f4',
      nameTh: 'ผัดไทยกุ้งสด',
      nameEn: 'Pad Thai with Prawns',
      calories: 560,
      protein: 24,
      fat: 20,
      carbs: 72,
      sodium: 1200,
      servingSize: '1 จาน',
      isVerified: true,
    ),
    Food(
      id: 'f5',
      nameTh: 'ข้าวมันไก่',
      nameEn: 'Hainanese Chicken Rice',
      calories: 590,
      protein: 30,
      fat: 24,
      carbs: 64,
      sodium: 1000,
      servingSize: '1 จาน',
      isVerified: true,
    ),
  ];

  static ScanResult get demoScan => ScanResult(
        scanId: 'demo-scan-1',
        confidence: 0.98,
        quota: const Quota(used: 1, limit: 3, tier: UserTier.free),
        items: [
          ScanItem(
            label: 'ข้าวผัดกะเพราไก่',
            confidence: 0.97,
            estimatedPortion: '1 จาน',
            grams: 350,
            matchedFood: demoFoods[0],
          ),
          ScanItem(
            label: 'ไข่ดาว',
            confidence: 0.94,
            estimatedPortion: '1 ฟอง',
            grams: 55,
            matchedFood: const Food(
              id: 'f6',
              nameTh: 'ไข่ดาว',
              nameEn: 'Fried Egg',
              calories: 90,
              protein: 6,
              fat: 7,
              carbs: 1,
              sodium: 95,
              servingSize: '1 ฟอง',
              isVerified: true,
            ),
          ),
        ],
      );

  static DayLog demoDayLog(String date) {
    final now = DateTime.now();
    return DayLog(
      date: date,
      summary: const DailySummary(
        calories: 1180,
        protein: 62,
        carbs: 140,
        fat: 41,
        sodium: 2400,
        target: 1600,
      ),
      logs: [
        MealLog(
          id: 'l1',
          foodId: 'f5',
          name: 'ข้าวมันไก่',
          mealType: MealType.breakfast,
          grams: 300,
          calories: 590,
          protein: 30,
          carbs: 64,
          fat: 24,
          sodium: 1000,
          loggedAt: DateTime(now.year, now.month, now.day, 8, 20),
        ),
        MealLog(
          id: 'l2',
          foodId: 'f3',
          name: 'ส้มตำไทย',
          mealType: MealType.lunch,
          grams: 200,
          calories: 180,
          protein: 5,
          carbs: 28,
          fat: 6,
          sodium: 900,
          loggedAt: DateTime(now.year, now.month, now.day, 12, 45),
        ),
        MealLog(
          id: 'l3',
          foodId: 'f2',
          name: 'ต้มยำกุ้ง',
          mealType: MealType.dinner,
          grams: 250,
          calories: 220,
          protein: 18,
          carbs: 14,
          fat: 9,
          sodium: 1400,
          loggedAt: DateTime(now.year, now.month, now.day, 19, 10),
        ),
      ],
    );
  }

  static List<WeightEntry> get demoWeights {
    final now = DateTime.now();
    final base = [61.0, 60.6, 60.1, 59.8, 59.3, 58.9, 58.5, 58.2];
    return List.generate(base.length, (i) {
      return WeightEntry(
        id: 'w$i',
        weightKg: base[i],
        loggedAt: now.subtract(Duration(days: (base.length - 1 - i) * 4)),
      );
    });
  }
}
