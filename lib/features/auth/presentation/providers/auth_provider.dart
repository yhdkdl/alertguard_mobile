import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../../contacts/presentation/providers/contact_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Tracks auth state: null = loading, true = logged in, false = logged out
final authStateProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.isLoggedIn();
});

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
    if (!state.hasError) {
      await _resetSessionFlags();
      _invalidateSessionScopedProviders();
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.login(email: email, password: password),
    );
    if (!state.hasError) {
      await _resetSessionFlags();
      _invalidateSessionScopedProviders();
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.logout());
    if (!state.hasError) {
      await _resetSessionFlags();
      _invalidateSessionScopedProviders();
    }
  }

  Future<void> _resetSessionFlags() async {
    // Prevent a previous account's safety mode from leaking into a new session.
    await ref.read(testModeProvider.notifier).setValue(false);
    ref.invalidate(testModeProvider);
  }

  void _invalidateSessionScopedProviders() {
    ref.invalidate(authStateProvider);
    ref.invalidate(contactsProvider);
    ref.invalidate(profileProvider);
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);
