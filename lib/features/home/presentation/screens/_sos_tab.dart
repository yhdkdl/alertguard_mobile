import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/services/trigger_service.dart';
import '../../../../core/services/alert_service.dart';

class SosTab extends ConsumerStatefulWidget {
  final Function(int)? onSwitchTab;
  const SosTab({super.key, this.onSwitchTab});

  @override
  ConsumerState<SosTab> createState() => _SosTabState();
}

class _SosTabState extends ConsumerState<SosTab> {
  late TriggerService _triggerService;
  bool _isCounting = false;
  int _countdown = 5;
  AlertResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _initTriggerService();
  }

  void _initTriggerService() {
    _triggerService = TriggerService(
      onCountdownStart: () {
        if (mounted)
          setState(() {
            _isCounting = true;
            _countdown = 5;
          });
      },
      onCountdownTick: (seconds) {
        if (mounted) setState(() => _countdown = seconds);
      },
      onAlertSent: (result) {
        if (mounted) {
          setState(() {
            _isCounting = false;
            _lastResult = result;
          });
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _lastResult = null);
          });
        }
      },
      onAlertCancelled: () {
        if (mounted) setState(() => _isCounting = false);
      },
    );

    // Read all settings before arming
    Future.wait([
      ref.read(silentModeProvider.future),
      ref.read(testModeProvider.future),
      ref.read(volumeTriggerProvider.future),
      ref.read(shakeTriggerProvider.future),
    ]).then((values) {
      _triggerService.setSilentMode(values[0] as bool);
      _triggerService.setTestMode(values[1] as bool);
      _triggerService.setVolumeEnabled(values[2] as bool);
      _triggerService.setShakeEnabled(values[3] as bool);
      _triggerService.arm();
    });
  }

  @override
  void dispose() {
    _triggerService.disarm();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final silentMode = ref.watch(silentModeProvider);
    final testMode = ref.watch(testModeProvider);
    final volumeEnabled = ref.watch(volumeTriggerProvider);
    final shakeEnabled = ref.watch(shakeTriggerProvider);

    // Keep service in sync with provider changes
    silentMode.whenData((v) => _triggerService.setSilentMode(v));
    testMode.whenData((v) => _triggerService.setTestMode(v));
    volumeEnabled.whenData((v) => _triggerService.setVolumeEnabled(v));
    shakeEnabled.whenData((v) => _triggerService.setShakeEnabled(v));

    final bool isTestActive = testMode.maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AlertGuard'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          silentMode.when(
            data: (isSilent) => IconButton(
              icon: Icon(isSilent ? Icons.volume_off : Icons.volume_up),
              tooltip: isSilent ? 'Silent mode on' : 'Silent mode off',
              onPressed: () => ref.read(silentModeProvider.notifier).toggle(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              _triggerService.disarm();
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Test mode banner ─────────────────────────────
              if (isTestActive)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  color: Colors.orange,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.science, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'TEST MODE — Contacts will NOT be notified',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Active triggers indicator ─────────────────────
              _ActiveTriggersBar(
                volumeEnabled: volumeEnabled.maybeWhen(
                  data: (v) => v,
                  orElse: () => true,
                ),
                shakeEnabled: shakeEnabled.maybeWhen(
                  data: (v) => v,
                  orElse: () => true,
                ),
              ),

              // ── SOS UI ───────────────────────────────────────
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Result feedback banner
                      if (_lastResult != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _lastResult == AlertResult.sent
                                ? Colors.green
                                : _lastResult == AlertResult.queued
                                ? Colors.orange
                                : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _lastResult == AlertResult.sent
                                    ? Icons.check_circle
                                    : _lastResult == AlertResult.queued
                                    ? Icons.schedule
                                    : Icons.error,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _lastResult == AlertResult.sent
                                    ? isTestActive
                                          ? 'Test Alert Sent to Your Telegram'
                                          : 'SOS Alert Sent'
                                    : _lastResult == AlertResult.queued
                                    ? 'Alert Queued — will send when online'
                                    : 'Alert Failed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // SOS Button
                      GestureDetector(
                        onTap: _isCounting
                            ? () => _triggerService.cancelCountdown()
                            : () => _triggerService.triggerManual(),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCounting
                                ? Colors.orange
                                : isTestActive
                                ? Colors.orange.shade700
                                : Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_isCounting || isTestActive
                                            ? Colors.orange
                                            : Colors.red)
                                        .withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isCounting
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$_countdown',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 64,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'tap to cancel',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'SOS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 52,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                      if (isTestActive)
                                        const Text(
                                          'TEST',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Text(
                        _isCounting
                            ? 'Sending in $_countdown seconds...'
                            : isTestActive
                            ? 'Test mode — only you will be notified'
                            : 'Press SOS or use the other built in triggers ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Cancel overlay during countdown
          if (_isCounting)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => _triggerService.cancelCountdown(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  icon: const Icon(Icons.cancel),
                  label: const Text(
                    'Cancel Alert',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Active Triggers Indicator Bar ─────────────────────────────────
// Shows the user which triggers are currently active
// so they always know how they can trigger an alert.

class _ActiveTriggersBar extends StatelessWidget {
  final bool volumeEnabled;
  final bool shakeEnabled;

  const _ActiveTriggersBar({
    required this.volumeEnabled,
    required this.shakeEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.grey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Active triggers: ',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          _TriggerChip(
            icon: Icons.touch_app,
            label: 'Manual',
            enabled: true, // always on
          ),
          if (volumeEnabled) ...[
            const SizedBox(width: 6),
            _TriggerChip(icon: Icons.volume_up, label: 'Volume', enabled: true),
          ],
          if (shakeEnabled) ...[
            const SizedBox(width: 6),
            _TriggerChip(icon: Icons.vibration, label: 'Shake', enabled: true),
          ],
        ],
      ),
    );
  }
}

class _TriggerChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;

  const _TriggerChip({
    required this.icon,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: enabled ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Colors.red.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: enabled ? Colors.red : Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: enabled ? Colors.red : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
