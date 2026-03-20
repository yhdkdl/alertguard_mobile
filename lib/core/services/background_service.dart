import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Create the persistent notification channel (Android requires this)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'alertguard_foreground',
    'AlertGuard Protection',
    description: 'AlertGuard is actively monitoring for SOS triggers',
    importance: Importance.low, // low = no sound, just stays in tray
  );

  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundServiceStart,
      autoStart: true,
      isForegroundMode: true, // runs as foreground service
      notificationChannelId: 'alertguard_foreground',
      initialNotificationTitle: 'AlertGuard Active',
      initialNotificationContent: 'Monitoring for SOS triggers',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onBackgroundServiceStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) {
  // The background isolate runs trigger detection here
  // Volume and shake listeners are initialized in the main isolate
  // This keeps the process alive so they keep working
  service.on('stop').listen((event) {
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}
