import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/trigger_service.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/alert_service.dart';

class SosTab extends ConsumerStatefulWidget {
  const SosTab({super.key});

  @override
  ConsumerState<SosTab> createState() => _SosTabState();
}

class _SosTabState extends ConsumerState<SosTab> {
  late TriggerService _triggerService;
  bool _isCounting = false;
  int _countdown = 5;
  bool _alertSent = false;
  AlertResult? _lastResult;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
    _initTriggerService();
  }

  Future<void> _requestPermissions() async {
    await PermissionService.requestAllPermissions();
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
          // Reset after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _lastResult = null);
          });
        }
      },
      onAlertCancelled: () {
        if (mounted)
          setState(() {
            _isCounting = false;
            _countdown = 5;
          });
      },
    );

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
          silentMode.when(
            data: (isSilent) => IconButton(
              icon: Icon(isSilent ? Icons.volume_off : Icons.volume_up),
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                              ? 'SOS Alert Sent'
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
                GestureDetector(
                  onTap: _isCounting
                      ? () => _triggerService.cancelCountdown()
                      : () => _triggerService.triggerManual(),
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
                      : 'Press SOS or triple-press volume button',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
