import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

// The repository provider — single instance shared across the app
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Tracks auth state: null = loading, true = logged in, false = logged out
final authStateProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.isLoggedIn();
});

// Notifier handles register/login/logout actions
class AuthNotifier extends AsyncNotifier<void> {
  late AuthRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.read(authRepositoryProvider);
  }

  Future<void> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () =>
          _repo.register(email: email, fullName: fullName, password: password),
    );
    // Tell authStateProvider to re-check storage
    if (!state.hasError) {
      ref.invalidate(authStateProvider); // ← ADD THIS
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.login(email: email, password: password),
    );
    // Tell authStateProvider to re-check storage
    if (!state.hasError) {
      ref.invalidate(authStateProvider); // ← ADD THIS
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.logout());
    // Force router/auth guards to re-check token storage after logout.
    if (!state.hasError) {
      ref.invalidate(authStateProvider);
    }
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);
