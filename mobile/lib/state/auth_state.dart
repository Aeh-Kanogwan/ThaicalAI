import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../config.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import 'providers.dart';

/// Authentication / session status.
enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final Profile? profile;
  final DailyGoal? dailyGoal;
  final bool demoMode;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.profile,
    this.dailyGoal,
    this.demoMode = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasProfile => profile != null && dailyGoal != null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Profile? profile,
    DailyGoal? dailyGoal,
    bool? demoMode,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      profile: clearUser ? null : (profile ?? this.profile),
      dailyGoal: clearUser ? null : (dailyGoal ?? this.dailyGoal),
      demoMode: demoMode ?? this.demoMode,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _bootstrap();
  }

  final Ref _ref;

  ApiClient get _api => _ref.read(apiClientProvider);

  /// On launch: if a token exists, try to hydrate the session via GET /me.
  Future<void> _bootstrap() async {
    final token = await _api.tokenStorage.read();
    if (token == null || token.isEmpty) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final me = await _api.getMe();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: me.user,
        profile: me.profile,
        dailyGoal: me.dailyGoal,
      );
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _api.logout();
        state = state.copyWith(status: AuthStatus.unauthenticated);
      } else {
        // Server unreachable but token present — keep user in, demo fallback.
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    }
  }

  Future<void> login({required String email, required String password}) async {
    final res = await _api.login(email: email, password: password);
    await _hydrateAfterAuth(res.user);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final res =
        await _api.register(email: email, password: password, name: name);
    await _hydrateAfterAuth(res.user);
  }

  Future<void> _hydrateAfterAuth(User user) async {
    try {
      final me = await _api.getMe();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: me.user,
        profile: me.profile,
        dailyGoal: me.dailyGoal,
      );
    } on ApiException {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    }
  }

  /// PUT /me/profile — persists profile and stores the computed daily goal.
  Future<DailyGoal> saveProfile(Profile profile) async {
    try {
      final res = await _api.updateProfile(profile);
      state = state.copyWith(
        profile: res.profile,
        dailyGoal: res.dailyGoal,
      );
      return res.dailyGoal;
    } on ApiException catch (e) {
      if (AppConfig.demoFallbackEnabled && e.isNetwork) {
        // Compute a local estimate so onboarding can complete offline.
        final goal = _estimateGoal(profile);
        state =
            state.copyWith(profile: profile, dailyGoal: goal, demoMode: true);
        return goal;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Enter demo mode without a backend (Explore button on login).
  void enterDemoMode() {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: MockData.demoUser,
      profile: MockData.demoProfile,
      dailyGoal: _estimateGoal(MockData.demoProfile),
      demoMode: true,
    );
  }

  void upgradeToVip() {
    final u = state.user;
    if (u != null) state = state.copyWith(user: u.copyWith(tier: UserTier.vip));
  }

  /// Local Mifflin-St Jeor estimate (server is authoritative when online).
  DailyGoal _estimateGoal(Profile p) {
    final s = p.sex == Sex.male ? 5 : -161;
    final bmr =
        (10 * p.weightKg) + (6.25 * p.heightCm) - (5 * p.age) + s;
    const factors = {
      ActivityLevel.sedentary: 1.2,
      ActivityLevel.light: 1.375,
      ActivityLevel.moderate: 1.55,
      ActivityLevel.active: 1.725,
      ActivityLevel.veryActive: 1.9,
    };
    final tdee = bmr * (factors[p.activityLevel] ?? 1.2);
    double target = tdee;
    if (p.goal == Goal.lose) target = tdee - 400;
    if (p.goal == Goal.gain) target = tdee + 300;
    final cals = target.round();
    // 40% carbs / 30% protein / 30% fat.
    return DailyGoal(
      calories: cals,
      proteinG: (cals * 0.30) / 4,
      carbsG: (cals * 0.40) / 4,
      fatG: (cals * 0.30) / 9,
      bmr: bmr,
      tdee: tdee,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);
