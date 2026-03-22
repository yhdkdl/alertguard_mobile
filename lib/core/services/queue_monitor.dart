import 'dart:async';
import 'connectivity_service.dart';
import 'alert_service.dart';

class QueueMonitor {
  static QueueMonitor? _instance;
  static QueueMonitor get instance => _instance ??= QueueMonitor._();
  QueueMonitor._();

  StreamSubscription<bool>? _subscription;
  bool _isRetrying = false;

  /// Start monitoring connectivity.
  /// Called once when the app starts.
  void start() {
    if (_subscription != null) return; // already running

    print('[QueueMonitor] Started');

    _subscription = ConnectivityService().onConnectivityChanged.listen((
      hasInternet,
    ) async {
      if (!hasInternet) {
        print('[QueueMonitor] Internet lost');
        return;
      }

      // Internet restored — retry pending alerts
      if (_isRetrying) return; // prevent concurrent retries
      _isRetrying = true;

      try {
        print('[QueueMonitor] Internet restored — processing queue');
        await alertServiceInstance.retryPendingAlerts();
      } finally {
        _isRetrying = false;
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    print('[QueueMonitor] Stopped');
  }
}
