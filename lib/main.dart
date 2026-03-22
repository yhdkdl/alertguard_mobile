import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/services/background_service.dart';
import 'core/services/queue_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start background service so triggers work when app is minimized.
  // Do not crash app startup if service init fails on a device/config.
  try {
    await initializeBackgroundService();
    QueueMonitor.instance.start();
  } catch (e, st) {
    debugPrint('Background service init failed: $e');
    debugPrintStack(stackTrace: st);
  }

  runApp(const ProviderScope(child: AlertGuardApp()));
}

class AlertGuardApp extends ConsumerWidget {
  const AlertGuardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AlertGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
