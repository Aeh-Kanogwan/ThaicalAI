# CalThai AI — Mobile (Flutter)

AI-powered Thai food calorie tracker for **iOS + Android**. Snap a photo → get
calories & macros → log it. Built to the brand in `../UI Style.txt` (Mint Green
`#10B981`, coral accent for calories, Inter font, 8px rounded corners).

> This project was hand-authored without a local Flutter SDK. Run
> `flutter pub get` first — versions are pinned to a **Flutter 3.27+ / Dart 3.6+**
> baseline (uses `Color.withValues()` and `CardThemeData`).

---

## Run it (after installing Flutter)

```bash
cd mobile
flutter pub get
flutter run            # pick an emulator/device
```

### API base URL — IMPORTANT
Configured in `lib/config.dart`, resolved automatically:
- **iOS simulator / desktop / web** → `http://localhost:4000`
- **Android emulator** → `http://10.0.2.2:4000` (emulator alias to host machine)

Change ports/hosts there. The version prefix `/api/v1` is appended automatically.

### Demo mode
`AppConfig.demoFallbackEnabled = true` (default). Real API calls are always
attempted first; if the backend is unreachable, screens fall back to mock data
(`lib/data/mock_data.dart`) so the whole app is explorable before the backend is
running. The Welcome screen also has an **"Explore in demo mode"** button that
skips auth entirely.

---

## Architecture

- **State:** `flutter_riverpod` — providers in `lib/state/`.
- **Networking:** `dio` client in `lib/api/api_client.dart` with a Bearer-token
  interceptor. Token is kept in `flutter_secure_storage` (`lib/api/token_storage.dart`).
- **Routing:** `go_router` in `lib/router.dart` with an auth+onboarding redirect
  guard (unauthenticated → Welcome; authenticated w/o profile → Profile setup).
- **Errors:** all HTTP failures normalize to `ApiException`
  (`isQuotaExceeded` on 402, `isUnauthorized` on 401, `isNetwork` on timeouts).
- **Theme:** `lib/theme/app_theme.dart` — colors, Inter via `google_fonts`,
  8px `AppRadius`, subtle card elevation.

```
lib/
  config.dart                 API base URL + pricing constants
  main.dart                   ProviderScope + MaterialApp.router
  router.dart                 go_router + redirect guard
  theme/app_theme.dart        design system (colors/typography/shapes)
  models/                     User, Profile, DailyGoal, Food, ScanResult+ScanItem,
                              MealLog(+CreateLogRequest, DailySummary, DayLog),
                              Quota, WeightEntry  (all fromJson/toJson)
  api/
    api_client.dart           typed dio client (all v1 endpoints)
    api_exception.dart        normalized error type
    token_storage.dart        secure JWT storage
  data/mock_data.dart         demo fallbacks
  state/
    providers.dart            apiClientProvider
    auth_state.dart           session (login/register/me/profile) + local goal est.
    daily_log_state.dart      selected date, day log, add/delete log actions
    quota_state.dart          AI scan quota
    weight_state.dart         weight entries + log action
  widgets/                    CalorieRing, MacroCard, ScanQuotaBadge, MealTile,
                              PrimaryButton, EmptyState
  screens/
    onboarding/               welcome_screen, profile_setup_screen
    auth/                     login_screen, register_screen
    home_shell.dart           bottom nav (Home/History/Profile) + center Scan FAB
    dashboard/                dashboard_screen (calorie ring, macros, meal timeline)
    scanner/                  scanner_screen (camera + animated scan overlay),
                              post_scan_sheet (results + serving/meal + Add to log)
    paywall/                  paywall_screen (Monthly ฿99 / Yearly ฿890, trial CTA)
    history/                  history_screen (fl_chart weight trend + weigh-ins)
    profile/                  profile_screen (info, goal, tier badge, logout)
```

---

## Screen → API endpoint map

| Screen | Endpoint(s) | Method |
|--------|-------------|--------|
| Register | `POST /api/v1/auth/register` | `ApiClient.register` |
| Login | `POST /api/v1/auth/login` | `ApiClient.login` |
| App launch (session hydrate) | `GET /api/v1/me` | `ApiClient.getMe` |
| Profile setup / edit | `PUT /api/v1/me/profile` → returns computed `dailyGoal` | `ApiClient.updateProfile` |
| Dashboard | `GET /api/v1/logs?date=YYYY-MM-DD` (+ `GET /api/v1/scan/quota` badge) | `ApiClient.getDayLog`, `getQuota` |
| Dashboard delete meal | `DELETE /api/v1/logs/:id` | `ApiClient.deleteLog` |
| Scanner (capture) | `POST /api/v1/scan` (multipart `image`) — 402 → Paywall | `ApiClient.scanImage` |
| Scanner quota badge | `GET /api/v1/scan/quota` | `ApiClient.getQuota` |
| Post-scan "Add to log" | `POST /api/v1/logs` | `ApiClient.createLog` |
| History chart | `GET /api/v1/weight?from=&to=` | `ApiClient.getWeightEntries` |
| History "Log weight" | `POST /api/v1/weight` | `ApiClient.logWeight` |
| Profile | uses cached `GET /me` data | — |
| Paywall CTA | **Phase 2 stub** (RevenueCat/IAP) — shows snackbar | — |

Also wired in the client (ready for future screens): `foods/search`, `foods/:id`,
`water` (POST/GET), `exercise` (POST).

---

## What a human must do after installing Flutter

1. **`flutter pub get`** in `mobile/`.
2. **Generate the platform runners.** This repo ships hand-authored
   `AndroidManifest.xml`, `ios/Runner/Info.plist`, and `MainActivity.kt` with the
   right permissions/labels, but **not** the full generated Gradle/Xcode scaffold.
   The clean way to get the rest without overwriting these files:
   ```bash
   # from mobile/, regenerate only the platform folders, then re-apply our files
   flutter create --platforms=android,ios --org ai.calthai .
   ```
   `flutter create .` will not clobber `lib/` or `pubspec.yaml`; review the diff on
   `AndroidManifest.xml` / `Info.plist` and keep our permission entries (see below).
3. **Camera permissions are already declared:**
   - Android: `CAMERA` + `INTERNET` in `android/app/src/main/AndroidManifest.xml`.
   - iOS: `NSCameraUsageDescription` (+ photo library) in `ios/Runner/Info.plist`.
4. **Cleartext HTTP for dev:** Android manifest sets `usesCleartextTraffic="true"`
   and iOS `Info.plist` allows arbitrary loads — **DEV ONLY** so the emulator can
   reach `http://10.0.2.2:4000` / `http://localhost:4000`. Remove/restrict before
   shipping (use HTTPS).
5. **App icons / launch screen:** placeholder from `flutter create`; replace with
   brand assets in `assets/` when available (the `assets/` folders are referenced
   in `pubspec.yaml` — add real files or remove the section if empty at build time).

---

## Assumptions

- `POST /scan` accepts multipart `image` (per contract); base64 path
  (`scanBase64`) is included as a fallback but the camera path sends a file.
- Post-scan combines all *matched* items into one log entry (primary dish name).
  Unmatched items are shown but not logged (contract says client offers manual
  search — a hook point for the `foods/search` screen).
- Serving-size Small/Regular/Large scales matched macros by 0.7 / 1.0 / 1.5.
- BMR/TDEE and macro split are **server-authoritative** (`PUT /me/profile`); the
  app computes a local Mifflin-St Jeor estimate only for offline/demo onboarding.
- Meal thumbnails use an icon placeholder — the API/`MealLog` has no image URL yet.
