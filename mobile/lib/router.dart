import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/paywall/paywall_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/scanner/scanner_screen.dart';
import 'state/auth_state.dart';

/// Route path constants.
class Routes {
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const profileSetup = '/onboarding/profile';
  static const dashboard = '/';
  static const history = '/history';
  static const profile = '/profile';
  static const scanner = '/scanner';
  static const paywall = '/paywall';
}

/// Bridges a [Listenable] to Riverpod so GoRouter re-evaluates redirects
/// whenever auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);

  return GoRouter(
    initialLocation: Routes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // Wait for bootstrap to resolve.
      if (auth.status == AuthStatus.unknown) return null;

      final loggedIn = auth.isAuthenticated;
      final authRoutes = {Routes.welcome, Routes.login, Routes.register};
      final onAuthRoute = authRoutes.contains(loc);

      if (!loggedIn) {
        return onAuthRoute ? null : Routes.welcome;
      }

      // Logged in but profile not set → force onboarding.
      if (!auth.hasProfile && loc != Routes.profileSetup) {
        return Routes.profileSetup;
      }

      // Logged in and on an auth route → go home.
      if (onAuthRoute) return Routes.dashboard;

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.profileSetup,
        builder: (_, __) => const ProfileSetupScreen(),
      ),
      // Main tabbed shell (Home / History / Profile + center Scan FAB).
      GoRoute(
        path: Routes.dashboard,
        builder: (_, __) => const HomeShell(initialTab: 0),
      ),
      GoRoute(
        path: Routes.history,
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.scanner,
        builder: (_, __) => const ScannerScreen(),
      ),
      GoRoute(
        path: Routes.paywall,
        builder: (_, __) => const PaywallScreen(),
      ),
    ],
  );
});
