import type { Food, MealLog, User } from '@prisma/client';

export function serializeUser(u: User) {
  return {
    id: u.id,
    email: u.email,
    name: u.name,
    tier: u.tier,
    createdAt: u.createdAt.toISOString(),
  };
}

// Food shape per API_CONTRACT: keywords/createdAt are intentionally omitted.
export function serializeFood(f: Food) {
  return {
    id: f.id,
    nameTh: f.nameTh,
    nameEn: f.nameEn,
    calories: f.calories,
    protein: f.protein,
    fat: f.fat,
    carbs: f.carbs,
    sodium: f.sodium,
    servingSize: f.servingSize,
    isVerified: f.isVerified,
  };
}

// MealLog shape per API_CONTRACT: `name` = customName ?? food name (resolved by caller).
export function serializeMealLog(log: MealLog, name: string) {
  return {
    id: log.id,
    foodId: log.foodId,
    name,
    mealType: log.mealType,
    grams: log.grams,
    calories: log.calories,
    protein: log.protein,
    carbs: log.carbs,
    fat: log.fat,
    sodium: log.sodium,
    loggedAt: log.loggedAt.toISOString(),
  };
}
