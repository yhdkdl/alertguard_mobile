import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/auth_repository.dart';
import '../../../../core/services/permission_service.dart';
import '../../../contacts/presentation/providers/contact_provider.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../home/presentation/widgets/setup_checklist.dart';
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
  static const _permissionsRequestedKey = 'permissions_requested_once';
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
      // Do not block navigation on first-run permission dialogs.
      unawaited(_requestPermissionsOnFirstLogin());
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
      // Do not block navigation on first-run permission dialogs.
      unawaited(_requestPermissionsOnFirstLogin());
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

  Future<void> _requestPermissionsOnFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyRequested = prefs.getBool(_permissionsRequestedKey) ?? false;
    if (alreadyRequested) return;

    await PermissionService.requestAllPermissions();
    await prefs.setBool(_permissionsRequestedKey, true);
  }

  void _invalidateSessionScopedProviders() {
    ref.invalidate(authStateProvider);
    ref.invalidate(contactsProvider);
    ref.invalidate(alertHistoryProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(setupStatusProvider);
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, void>(
  AuthNotifier.new,
);
