import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: notifier,
    redirect: (context, state) async {
      final onboardingDone = await ref.read(onboardingProvider.future);
      final isLoggedIn = await ref.read(authStateProvider.future);

      final path = state.matchedLocation;

      // Step 1 — Show onboarding first if never seen
      if (!onboardingDone) {
        if (path != '/onboarding') return '/onboarding';
        return null;
      }

      // Step 2 — Onboarding done, handle auth
      final isOnAuthRoute = path == '/login' || path == '/register';
      final isOnOnboarding = path == '/onboarding';

      // Redirect away from onboarding if already done
      if (isOnOnboarding) {
        return isLoggedIn ? '/home' : '/login';
      }

      // Redirect to home if logged in and on auth screen
      if (isLoggedIn && isOnAuthRoute) return '/home';

      // Redirect to login if not logged in
      if (!isLoggedIn && !isOnAuthRoute) return '/login';

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(onboardingProvider, (_, __) => notifyListeners());
  }
}
