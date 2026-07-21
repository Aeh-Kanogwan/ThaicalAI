# CalThai AI — API Contract (v1)

Base URL (dev): `http://localhost:4000`
All responses JSON. Auth via `Authorization: Bearer <jwt>`.
Errors: `{ "error": { "code": string, "message": string } }` with appropriate HTTP status.

---

## Auth

### POST /api/v1/auth/register
Body: `{ email, password, name }`
→ 201 `{ token, user }`

### POST /api/v1/auth/login
Body: `{ email, password }`
→ 200 `{ token, user }`

`user`: `{ id, email, name, tier: "free"|"vip", createdAt }`

---

## Profile & Goals

### GET /api/v1/me   (auth)
→ 200 `{ user, profile, dailyGoal }`

### PUT /api/v1/me/profile   (auth)
Body: `{ sex: "male"|"female", age, heightCm, weightKg, activityLevel, goal }`
- activityLevel: `"sedentary"|"light"|"moderate"|"active"|"very_active"`
- goal: `"lose"|"maintain"|"gain"`
→ 200 `{ profile, dailyGoal }`
- Server computes BMR (Mifflin-St Jeor) + TDEE + calorie target & macro split.

`dailyGoal`: `{ calories, proteinG, carbsG, fatG, bmr, tdee }`

---

## Foods

### GET /api/v1/foods/search?q=<text>&limit=20   (auth)
Matches `name_th`, `name_en`, and `keywords`.
→ 200 `{ items: Food[] }`

`Food`: `{ id, nameTh, nameEn, calories, protein, fat, carbs, sodium, servingSize, isVerified }`

### GET /api/v1/foods/:id   (auth)
→ 200 `{ food: Food }`

---

## AI Scan (Hero Feature)

### POST /api/v1/scan   (auth)
Multipart form: field `image` (jpeg/png) OR JSON `{ imageBase64 }`.
Consumes 1 daily scan quota. If quota exhausted → 402
`{ error: { code: "QUOTA_EXCEEDED", message } }`.

Flow: image → Vision provider → returns detected items → matched against foods DB.
→ 200
```json
{
  "scanId": "string",
  "confidence": 0.98,
  "items": [
    {
      "label": "ข้าวผัดกะเพราไก่",
      "confidence": 0.97,
      "estimatedPortion": "1 จาน",
      "matchedFood": { "...Food": true },
      "grams": 350
    }
  ],
  "quota": { "used": 4, "limit": 10, "resetAt": "ISO" }
}
```
Unmatched item → `matchedFood: null` (client offers manual search).

### GET /api/v1/scan/quota   (auth)
→ 200 `{ used, limit, resetAt, tier }`
- Free: limit 3 total (lifetime trial). VIP: 10/day.

---

## Meal Logs

### POST /api/v1/logs   (auth)
Body:
```json
{
  "foodId": "string|null",
  "customName": "string|null",
  "mealType": "breakfast"|"lunch"|"dinner"|"snack",
  "grams": 350,
  "calories": 520, "protein": 30, "carbs": 60, "fat": 18, "sodium": 900,
  "scanId": "string|null",
  "loggedAt": "ISO (optional, default now)"
}
```
→ 201 `{ log: MealLog }`

### GET /api/v1/logs?date=YYYY-MM-DD   (auth)
→ 200 `{ date, summary: { calories, protein, carbs, fat, sodium, target }, logs: MealLog[] }`

### DELETE /api/v1/logs/:id   (auth) → 204

`MealLog`: `{ id, foodId, name, mealType, grams, calories, protein, carbs, fat, sodium, loggedAt }`

---

## Water & Exercise

### POST /api/v1/water   (auth)  Body: `{ ml, loggedAt? }` → 201
### GET  /api/v1/water?date=YYYY-MM-DD (auth) → `{ totalMl, entries[] }`
### POST /api/v1/exercise (auth) Body: `{ name, minutes, caloriesBurned, loggedAt? }` → 201

---

## Weight Tracker

### POST /api/v1/weight (auth) Body: `{ weightKg, photoUrl?, loggedAt? }` → 201
### GET  /api/v1/weight?from=&to= (auth) → `{ entries: [{ id, weightKg, photoUrl, loggedAt }] }`

---

## Notes for implementers
- JWT secret via env `JWT_SECRET`.
- All list endpoints scope to the authenticated user.
- Vision provider selected via env `VISION_PROVIDER=mock|openai|gemini`; default `mock` in dev.
- Macro split default: 40% carbs / 30% protein / 30% fat (adjust by goal on server).
