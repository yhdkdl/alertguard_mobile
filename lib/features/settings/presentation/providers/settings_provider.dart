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

// ── Trigger Preferences ───────────────────────────────────────────
// Each hardware trigger can be independently enabled or disabled.
// The manual SOS button is always enabled and has no toggle.

class _TriggerPrefNotifier extends AsyncNotifier<bool> {
  final String key;
  final bool defaultValue;

  _TriggerPrefNotifier({required this.key, required this.defaultValue});

  @override
  Future<bool> build() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<void> setValue(bool value) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(key, value);
    state = AsyncData(value);
  }
}

// Volume button trigger — enabled by default
final volumeTriggerProvider = AsyncNotifierProvider<_TriggerPrefNotifier, bool>(
  () => _TriggerPrefNotifier(key: 'trigger_volume', defaultValue: true),
);

// Shake trigger — enabled by default
final shakeTriggerProvider = AsyncNotifierProvider<_TriggerPrefNotifier, bool>(
  () => _TriggerPrefNotifier(key: 'trigger_shake', defaultValue: true),
);
