import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // This notifier tells GoRouter to re-evaluate redirect
  // whenever auth state changes
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier, // ← KEY: re-runs redirect on auth change
    redirect: (context, state) async {
      final isLoggedIn = await ref.read(authStateProvider.future);
      final isOnAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isLoggedIn && isOnAuthRoute) return '/home';
      if (!isLoggedIn && !isOnAuthRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
});

// Listens to Riverpod auth state and notifies GoRouter to re-run redirect
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    // Watch authStateProvider — call notifyListeners when it changes
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
