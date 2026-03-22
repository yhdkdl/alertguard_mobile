import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

// ── Silent Mode ───────────────────────────────────────────────────

class SilentModeNotifier extends AsyncNotifier<bool> {
  static const _key = 'silent_mode';

  @override
  Future<bool> build() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final current = state.value ?? false;
    await prefs.setBool(_key, !current);
    state = AsyncData(!current);
  }
}

final silentModeProvider = AsyncNotifierProvider<SilentModeNotifier, bool>(
  SilentModeNotifier.new,
);

// ── Test Mode ─────────────────────────────────────────────────────

class TestModeNotifier extends AsyncNotifier<bool> {
  static const _key = 'test_mode';

  @override
  Future<bool> build() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final current = state.value ?? false;
    await prefs.setBool(_key, !current);
    state = AsyncData(!current);
  }

  Future<void> setValue(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_key, value);
    state = AsyncData(value);
  }
}

final testModeProvider = AsyncNotifierProvider<TestModeNotifier, bool>(
  TestModeNotifier.new,
);
