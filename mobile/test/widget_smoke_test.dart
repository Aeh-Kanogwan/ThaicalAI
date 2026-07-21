import 'package:calthai_ai/models/models.dart';
import 'package:calthai_ai/theme/app_theme.dart';
import 'package:calthai_ai/widgets/calorie_ring.dart';
import 'package:calthai_ai/widgets/macro_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('models', () {
    test('DailyGoal round-trips through JSON', () {
      final json = {
        'calories': 1800,
        'proteinG': 135.0,
        'carbsG': 180.0,
        'fatG': 60.0,
        'bmr': 1400.0,
        'tdee': 1800.0,
      };
      final goal = DailyGoal.fromJson(json);
      expect(goal.calories, 1800);
      expect(goal.proteinG, 135.0);
      expect(goal.toJson()['carbsG'], 180.0);
    });

    test('ScanResult parses items and unmatched food', () {
      final json = {
        'scanId': 's1',
        'confidence': 0.98,
        'items': [
          {
            'label': 'ข้าวผัดกะเพราไก่',
            'confidence': 0.97,
            'estimatedPortion': '1 จาน',
            'grams': 350,
            'matchedFood': {
              'id': 'f1',
              'nameTh': 'ข้าวผัดกะเพราไก่',
              'calories': 620,
              'protein': 28,
              'fat': 22,
              'carbs': 78,
              'servingSize': '1 จาน',
              'isVerified': true,
            },
          },
          {
            'label': 'unknown',
            'confidence': 0.4,
            'grams': 50,
            'matchedFood': null,
          },
        ],
        'quota': {'used': 4, 'limit': 10, 'tier': 'vip'},
      };
      final result = ScanResult.fromJson(json);
      expect(result.items.length, 2);
      expect(result.items.first.isMatched, true);
      expect(result.items.last.isMatched, false);
      expect(result.quota.remaining, 6);
      expect(result.confidencePct, 98);
    });

    test('Quota exhaustion', () {
      const q = Quota(used: 3, limit: 3);
      expect(q.isExhausted, true);
      expect(q.remaining, 0);
    });

    test('ActivityLevel serializes very_active correctly', () {
      expect(ActivityLevel.veryActive.asJson, 'very_active');
      expect(ActivityLevel.fromString('very_active'), ActivityLevel.veryActive);
    });
  });

  group('widgets', () {
    testWidgets('CalorieRing shows kcal left', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: Center(child: CalorieRing(consumed: 1200, goal: 2000)),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Kcal left'), findsOneWidget);
      expect(find.text('800'), findsOneWidget);
    });

    testWidgets('MacroCard renders label and values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: MacroCard(
              label: 'Protein',
              consumedG: 60,
              targetG: 120,
              color: AppColors.protein,
            ),
          ),
        ),
      );
      expect(find.text('Protein'), findsOneWidget);
      expect(find.textContaining('120 g'), findsOneWidget);
    });
  });
}
