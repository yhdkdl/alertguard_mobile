import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/trigger_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late TriggerService _triggerService;
  bool _isCounting = false;
  int _countdown = 5;
  bool _alertSent = false;

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
      onAlertSent: () {
        if (mounted)
          setState(() {
            _isCounting = false;
            _alertSent = true;
          });
        // Reset the sent confirmation after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _alertSent = false);
        });
      },
      onAlertCancelled: () {
        if (mounted) setState(() => _isCounting = false);
      },
    );

    // Read current silent mode and arm the service
    ref.read(silentModeProvider.future).then((silentMode) {
      _triggerService.setSilentMode(silentMode);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('AlertGuard'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          // Silent mode toggle
          silentMode.when(
            data: (isSilent) => IconButton(
              icon: Icon(isSilent ? Icons.volume_off : Icons.volume_up),
              tooltip: isSilent ? 'Silent mode on' : 'Silent mode off',
              onPressed: () {
                ref.read(silentModeProvider.notifier).toggle();
                _triggerService.setSilentMode(!isSilent);
              },
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
          // ── Main content ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Alert sent confirmation
                if (_alertSent)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'SOS Alert Sent',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // SOS Button
                GestureDetector(
                  onTap: () => _triggerService.triggerManual(),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isCounting ? Colors.orange : Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: (_isCounting ? Colors.orange : Colors.red)
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
                          : const Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  _isCounting
                      ? 'Sending alert in $_countdown seconds...'
                      : 'Press SOS or double-press volume button',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // ── Cancel overlay during countdown ──
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
