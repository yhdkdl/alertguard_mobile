import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:volume_controller/volume_controller.dart';
import 'alert_service.dart';

enum TriggerType { volumeButton, shake, manual }

class TriggerService {
  static const int countdownSeconds = 5;

  final VoidCallback? onCountdownStart;
  final Function(AlertResult)? onAlertSent;
  final VoidCallback? onAlertCancelled;
  final Function(int)? onCountdownTick;

  TriggerService({
    this.onCountdownStart,
    this.onAlertSent,
    this.onAlertCancelled,
    this.onCountdownTick,
  });

  bool _silentMode = false;
  bool _isArmed = false;
  bool _isCounting = false;
  Timer? _countdownTimer;

  // Volume button tracking
  double? _lastVolume;
  DateTime? _lastVolumeChange;
  int _volumePressCount = 0;

  // Shake detection
  StreamSubscription? _accelerometerSub;
  DateTime? _lastShakeTime;
  int _shakeCount = 0;

  void setSilentMode(bool value) => _silentMode = value;

  void arm() {
    if (_isArmed) return;
    _isArmed = true;
    _startVolumeListener();
    _startShakeDetector();
  }

  void disarm() {
    _isArmed = false;
    _countdownTimer?.cancel();
    _accelerometerSub?.cancel();
    VolumeController().removeListener();
  }

  void triggerManual() {
    if (!_isArmed || _isCounting) return;
    _onTriggerDetected(TriggerType.manual);
  }

  void cancelCountdown() {
    if (!_isCounting) return;
    _countdownTimer?.cancel();
    _isCounting = false;
    onAlertCancelled?.call();
  }

  void _startVolumeListener() {
    VolumeController().listener((volume) {
      final now = DateTime.now();

      if (_lastVolume == null) {
        _lastVolume = volume;
        return;
      }

      if ((volume - _lastVolume!).abs() > 0.01) {
        _lastVolume = volume;

        if (_lastVolumeChange != null &&
            now.difference(_lastVolumeChange!).inSeconds > 2) {
          _volumePressCount = 0;
        }

        _volumePressCount++;
        _lastVolumeChange = now;

        // Require 3 consecutive volume changes within 2 seconds.
        if (_volumePressCount >= 3) {
          _volumePressCount = 0;
          _onTriggerDetected(TriggerType.volumeButton);
        }
      }
    });
  }

  void _startShakeDetector() {
    const double shakeThreshold = 15.0;
    const Duration shakeWindow = Duration(seconds: 2);
    const Duration shakeDebounce = Duration(milliseconds: 700);

    _accelerometerSub = accelerometerEventStream().listen((event) {
      if (!_isArmed || _isCounting) return;

      final double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.8;

      if (magnitude > shakeThreshold) {
        final now = DateTime.now();

        // Debounce spikes from one shake motion.
        if (_lastShakeTime != null &&
            now.difference(_lastShakeTime!) < shakeDebounce) {
          return;
        }

        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!) > shakeWindow) {
          _shakeCount = 0;
        }

        _shakeCount++;
        _lastShakeTime = now;

        // Require 2 shakes within shakeWindow.
        if (_shakeCount >= 2) {
          _shakeCount = 0;
          _lastShakeTime = null;
          _onTriggerDetected(TriggerType.shake);
        }
      }
    });
  }

  void _onTriggerDetected(TriggerType type) {
    if (_isCounting) return;

    if (_silentMode) {
      _vibrateAlert();
      _sendAlert(type);
    } else {
      _startCountdown(type);
    }
  }

  void _startCountdown(TriggerType type) {
    _isCounting = true;
    int remaining = countdownSeconds;

    onCountdownStart?.call();
    onCountdownTick?.call(remaining);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      onCountdownTick?.call(remaining);

      if (remaining <= 0) {
        timer.cancel();
        _isCounting = false;
        _sendAlert(type);
      }
    });
  }

  Future<void> _sendAlert(TriggerType type) async {
    final result = await alertServiceInstance.sendAlert(
      triggerType: _triggerTypeToString(type),
    );
    onAlertSent?.call(result); // passes result to UI
  }

  Future<void> _vibrateAlert() async {
    await HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 200));
    await HapticFeedback.vibrate();
  }

  String _triggerTypeToString(TriggerType type) {
    switch (type) {
      case TriggerType.volumeButton:
        return 'volume_button';
      case TriggerType.shake:
        return 'shake';
      case TriggerType.manual:
        return 'manual';
    }
  }
}
