import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();
  final _checker = InternetConnection();

  // Stream that emits true when internet is available, false when not
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.asyncMap((_) => hasInternet());
  }

  /// Returns true if device has real internet access
  static Future<bool> hasInternet() async {
    try {
      return await InternetConnection().hasInternetAccess;
    } catch (e) {
      print('[Connectivity] Check failed: $e');
      return false;
    }
  }
}
