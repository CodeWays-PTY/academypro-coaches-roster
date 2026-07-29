import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkStatusNotifier extends StateNotifier<bool> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicCheckTimer;

  NetworkStatusNotifier() : super(true) {
    _init();
  }

  void _init() {
    _checkRealConnection();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _checkRealConnection();
    });

    // Periodic check every 15 seconds to ensure continuous monitoring
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkRealConnection();
    });
  }

  Future<bool> checkRealConnection() async {
    return await _checkRealConnection();
  }

  Future<bool> _checkRealConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty || results.every((r) => r == ConnectivityResult.none)) {
        if (state != false) state = false;
        return false;
      }

      // Perform a lightweight lookup to confirm active data route
      final result = await InternetAddress.lookup('academypro-api.codeways.co')
          .timeout(const Duration(seconds: 4));
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (state != hasConnection) {
        state = hasConnection;
      }
      return hasConnection;
    } catch (_) {
      // Direct lookup fallback check to secondary DNS/Host
      try {
        final fallback = await InternetAddress.lookup('one.one.one.one')
            .timeout(const Duration(seconds: 3));
        final hasConnection = fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty;
        if (state != hasConnection) {
          state = hasConnection;
        }
        return hasConnection;
      } catch (_) {
        if (state != false) state = false;
        return false;
      }
    }
  }

  void markOffline() {
    if (state != false) state = false;
  }

  void markOnline() {
    if (state != true) state = true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _periodicCheckTimer?.cancel();
    super.dispose();
  }
}

final networkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, bool>((ref) {
  return NetworkStatusNotifier();
});
