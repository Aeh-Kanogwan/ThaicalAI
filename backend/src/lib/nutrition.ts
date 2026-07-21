import type { ActivityLevel, Goal, Sex } from '@prisma/client';

// Mifflin-St Jeor Equation.
//   male:   BMR = 10*kg + 6.25*cm - 5*age + 5
//   female: BMR = 10*kg + 6.25*cm - 5*age - 161
export function calcBmr(input: {
  sex: Sex;
  weightKg: number;
  heightCm: number;
  age: number;
}): number {
  const base = 10 * input.weightKg + 6.25 * input.heightCm - 5 * input.age;
  return input.sex === 'male' ? base + 5 : base - 161;
}

const ACTIVITY_FACTOR: Record<ActivityLevel, number> = {
  sedentary: 1.2,
  light: 1.375,
  moderate: 1.55,
  active: 1.725,
  very_active: 1.9,
};

export function calcTdee(bmr: number, activityLevel: ActivityLevel): number {
  return bmr * ACTIVITY_FACTOR[activityLevel];
}

// Goal adjustment: lose -15%, gain +15%, maintain unchanged.
const GOAL_FACTOR: Record<Goal, number> = {
  lose: 0.85,
  maintain: 1.0,
  gain: 1.15,
};

export interface DailyGoal {
  calories: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  bmr: number;
  tdee: number;
}

// Macro split default 40% carbs / 30% protein / 30% fat.
// 1g carb = 4 kcal, 1g protein = 4 kcal, 1g fat = 9 kcal.
export function computeDailyGoal(input: {
  sex: Sex;
  weightKg: number;
  heightCm: number;
  age: number;
  activityLevel: ActivityLevel;
  goal: Goal;
}): DailyGoal {
  const bmr = calcBmr(input);
  const tdee = calcTdee(bmr, input.activityLevel);
  const calories = tdee * GOAL_FACTOR[input.goal];

  const carbsG = (calories * 0.4) / 4;
  const proteinG = (calories * 0.3) / 4;
  const fatG = (calories * 0.3) / 9;

  return {
    calories: Math.round(calories),
    proteinG: Math.round(proteinG),
    carbsG: Math.round(carbsG),
    fatG: Math.round(fatG),
    bmr: Math.round(bmr),
    tdee: Math.round(tdee),
  };
}
