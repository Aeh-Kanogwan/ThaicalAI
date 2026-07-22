import { describe, it, expect } from 'vitest';
import { calcBmr, calcTdee, computeDailyGoal } from '../nutrition.js';

// Mifflin-St Jeor:
//   male   BMR = 10*kg + 6.25*cm - 5*age + 5
//   female BMR = 10*kg + 6.25*cm - 5*age - 161
describe('calcBmr (Mifflin-St Jeor)', () => {
  it('male 30y/175cm/70kg → 1648.75 (rounds to 1649)', () => {
    const bmr = calcBmr({ sex: 'male', weightKg: 70, heightCm: 175, age: 30 });
    // 700 + 1093.75 - 150 + 5
    expect(bmr).toBeCloseTo(1648.75, 5);
    expect(Math.round(bmr)).toBe(1649);
  });

  it('female 25y/165cm/60kg → 1345.25 (rounds to 1345)', () => {
    const bmr = calcBmr({ sex: 'female', weightKg: 60, heightCm: 165, age: 25 });
    // 600 + 1031.25 - 125 - 161
    expect(bmr).toBeCloseTo(1345.25, 5);
    expect(Math.round(bmr)).toBe(1345);
  });

  it('differs by exactly 166 between male and female for identical body metrics', () => {
    const m = calcBmr({ sex: 'male', weightKg: 70, heightCm: 175, age: 30 });
    const f = calcBmr({ sex: 'female', weightKg: 70, heightCm: 175, age: 30 });
    expect(m - f).toBeCloseTo(166, 5); // (+5) - (-161)
  });
});

describe('calcTdee (activity factors)', () => {
  const bmr = 1648.75;
  const cases: Array<[Parameters<typeof calcTdee>[1], number]> = [
    ['sedentary', 1.2],
    ['light', 1.375],
    ['moderate', 1.55],
    ['active', 1.725],
    ['very_active', 1.9],
  ];

  for (const [level, factor] of cases) {
    it(`${level} → bmr * ${factor}`, () => {
      expect(calcTdee(bmr, level)).toBeCloseTo(bmr * factor, 5);
    });
  }

  it('moderate for BMR 1648.75 → 2555.5625 (rounds to 2556)', () => {
    const tdee = calcTdee(1648.75, 'moderate');
    expect(tdee).toBeCloseTo(2555.5625, 4);
    expect(Math.round(tdee)).toBe(2556);
  });

  it('edge activity levels: sedentary is lowest, very_active is highest', () => {
    expect(calcTdee(bmr, 'sedentary')).toBeLessThan(calcTdee(bmr, 'very_active'));
  });
});

describe('computeDailyGoal', () => {
  const male = {
    sex: 'male' as const,
    weightKg: 70,
    heightCm: 175,
    age: 30,
    activityLevel: 'moderate' as const,
  };

  it('maintain → calories == TDEE (2556), reports bmr/tdee', () => {
    const g = computeDailyGoal({ ...male, goal: 'maintain' });
    expect(g.bmr).toBe(1649);
    expect(g.tdee).toBe(2556);
    expect(g.calories).toBe(2556); // 2555.5625 * 1.0 → round
  });

  it('lose → TDEE * 0.85 (2172)', () => {
    const g = computeDailyGoal({ ...male, goal: 'lose' });
    // 2555.5625 * 0.85 = 2172.228 → 2172
    expect(g.calories).toBe(Math.round(2555.5625 * 0.85));
    expect(g.calories).toBe(2172);
    expect(g.calories).toBeLessThan(g.tdee);
  });

  it('gain → TDEE * 1.15 (2939)', () => {
    const g = computeDailyGoal({ ...male, goal: 'gain' });
    // 2555.5625 * 1.15 = 2938.897 → 2939
    expect(g.calories).toBe(Math.round(2555.5625 * 1.15));
    expect(g.calories).toBe(2939);
    expect(g.calories).toBeGreaterThan(g.tdee);
  });

  it('lose/gain adjustment is symmetric ±15% around maintain', () => {
    const lose = computeDailyGoal({ ...male, goal: 'lose' });
    const gain = computeDailyGoal({ ...male, goal: 'gain' });
    // Compare against the UNROUNDED tdee (2555.5625) — calories apply the factor
    // to the raw tdee then round once, so using the rounded tdee here drifts ~0.6.
    const rawTdee = 2555.5625;
    expect(lose.calories).toBe(Math.round(rawTdee * 0.85));
    expect(gain.calories).toBe(Math.round(rawTdee * 1.15));
  });

  it('macro split: 40% carbs / 30% protein / 30% fat by calories, sums back to ~calories', () => {
    const g = computeDailyGoal({ ...male, goal: 'maintain' });
    // Reconstruct kcal from macro grams: carb/protein 4 kcal/g, fat 9 kcal/g.
    const kcalFromMacros = g.carbsG * 4 + g.proteinG * 4 + g.fatG * 9;
    // Allow tolerance for gram rounding (each macro rounded to nearest gram).
    expect(kcalFromMacros).toBeGreaterThan(g.calories - 30);
    expect(kcalFromMacros).toBeLessThan(g.calories + 30);
    // carbs should carry the most grams (40% at 4 kcal/g).
    expect(g.carbsG).toBeGreaterThan(g.proteinG);
    expect(g.carbsG).toBeGreaterThan(g.fatG);
  });

  it('female case: 25y/165cm/60kg/sedentary/maintain → bmr 1345, tdee 1614', () => {
    const g = computeDailyGoal({
      sex: 'female',
      weightKg: 60,
      heightCm: 165,
      age: 25,
      activityLevel: 'sedentary',
      goal: 'maintain',
    });
    expect(g.bmr).toBe(1345);
    // 1345.25 * 1.2 = 1614.3 → 1614
    expect(g.tdee).toBe(1614);
    expect(g.calories).toBe(1614);
  });

  it('all fields are finite non-negative integers', () => {
    const g = computeDailyGoal({ ...male, goal: 'maintain' });
    for (const v of Object.values(g)) {
      expect(Number.isInteger(v)).toBe(true);
      expect(v).toBeGreaterThanOrEqual(0);
    }
  });
});
