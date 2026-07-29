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

    // Periodic check every 30 seconds to ensure continuous monitoring
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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

      // Perform resilient lookup against active API domain and primary fallbacks
      final hostsToTry = [
        'academypro-api.tata-elash34.workers.dev',
        'google.com',
        'cloudflare.com',
      ];

      bool hasConnection = false;
      for (final host in hostsToTry) {
        try {
          final result = await InternetAddress.lookup(host)
              .timeout(const Duration(seconds: 5));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            hasConnection = true;
            break;
          }
        } catch (_) {
          continue;
        }
      }

      // If domain lookups fail due to DNS latency, test direct IP socket connection to DNS servers
      if (!hasConnection) {
        try {
          final socket = await Socket.connect('1.1.1.1', 53, timeout: const Duration(seconds: 4));
          socket.destroy();
          hasConnection = true;
        } catch (_) {
          try {
            final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 4));
            socket.destroy();
            hasConnection = true;
          } catch (_) {
            hasConnection = false;
          }
        }
      }

      if (state != hasConnection) {
        state = hasConnection;
      }
      return hasConnection;
    } catch (_) {
      // On unexpected exceptions, check if physical interface is connected
      final results = await _connectivity.checkConnectivity();
      final isConnected = results.isNotEmpty && results.any((r) => r != ConnectivityResult.none);
      if (state != isConnected) state = isConnected;
      return isConnected;
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
