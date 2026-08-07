import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkStatusNotifier extends StateNotifier<bool> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicCheckTimer;
  Timer? _offlineDebounceTimer;

  /// Consecutive failed connection attempts — only go offline after 3 failures
  int _consecutiveFailures = 0;
  static const int _maxFailuresBeforeOffline = 3;

  NetworkStatusNotifier() : super(true) {
    _init();
  }

  void _init() {
    // Don't check immediately on init — assume online (the app just launched)
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasInterface = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);

      if (hasInterface) {
        // Interface available again — immediately reset failures and go online
        _offlineDebounceTimer?.cancel();
        _offlineDebounceTimer = null;
        _consecutiveFailures = 0;
        if (state != true) state = true;
      } else {
        // connectivity_plus says "none" — don't trust it immediately.
        // Wait 5 seconds, then do a real HTTP ping. This absorbs the brief
        // blips that Android/iOS fire during app switching & screen off.
        _offlineDebounceTimer?.cancel();
        _offlineDebounceTimer = Timer(const Duration(seconds: 5), () {
          _verifyWithHttpPing();
        });
      }
    });

    // Periodic check every 60 seconds (reduced frequency — less aggressive)
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      // Only do periodic checks if we're already marked offline,
      // to automatically recover. Don't disturb online state.
      if (!state) {
        _verifyWithHttpPing();
      }
    });
  }

  /// Called when the user explicitly taps "Retry Connection"
  Future<bool> checkRealConnection() async {
    _offlineDebounceTimer?.cancel();
    _offlineDebounceTimer = null;
    _consecutiveFailures = 0;
    return await _verifyWithHttpPing();
  }

  /// Called when app resumes from background — optimistic, resets failures
  void onAppResumed() {
    _offlineDebounceTimer?.cancel();
    _offlineDebounceTimer = null;
    _consecutiveFailures = 0;
    // Optimistically go online on resume — the app was just in background,
    // connectivity events during background are unreliable
    if (state != true) state = true;
  }

  /// Actually verify internet by doing an HTTP HEAD request.
  /// Only marks offline after [_maxFailuresBeforeOffline] consecutive failures.
  Future<bool> _verifyWithHttpPing() async {
    if (kIsWeb) {
      _consecutiveFailures = 0;
      if (state != true) state = true;
      return true;
    }

    // 1. Quick interface check first
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty && results.any((r) => r != ConnectivityResult.none)) {
        // Interface is connected — trust it, reset failures, go online
        _consecutiveFailures = 0;
        if (state != true) state = true;
        return true;
      }
    } catch (_) {
      // connectivity_plus threw — don't trust it, try HTTP ping instead
    }

    // 2. Interface says "none" — do a real HTTP ping to confirm
    final hasInternet = await _httpPing();
    if (hasInternet) {
      _consecutiveFailures = 0;
      if (state != true) state = true;
      return true;
    }

    // 3. HTTP ping also failed — increment failure counter
    _consecutiveFailures++;
    debugPrint('[NetworkService] Connection check failed ($_consecutiveFailures/$_maxFailuresBeforeOffline)');

    if (_consecutiveFailures >= _maxFailuresBeforeOffline) {
      if (state != false) state = false;
      return false;
    }

    // Haven't hit the threshold yet — schedule another check in 3 seconds
    _offlineDebounceTimer?.cancel();
    _offlineDebounceTimer = Timer(const Duration(seconds: 3), () {
      _verifyWithHttpPing();
    });

    // Don't change state yet — still "online" until 3 failures
    return true;
  }

  /// Lightweight HTTP HEAD to confirm actual internet access.
  /// Uses multiple fallback endpoints for reliability.
  Future<bool> _httpPing() async {
    final endpoints = [
      'https://clients3.google.com/generate_204',
      'https://www.gstatic.com/generate_204',
      'https://connectivitycheck.android.com/generate_204',
    ];

    for (final url in endpoints) {
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 4);
        final request = await client.headUrl(Uri.parse(url));
        final response = await request.close().timeout(const Duration(seconds: 4));
        client.close(force: true);
        if (response.statusCode >= 200 && response.statusCode < 400) {
          return true;
        }
      } catch (_) {
        // Try next endpoint
      }
    }
    return false;
  }

  void markOffline() {
    _consecutiveFailures = _maxFailuresBeforeOffline;
    if (state != false) state = false;
  }

  void markOnline() {
    _consecutiveFailures = 0;
    if (state != true) state = true;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _periodicCheckTimer?.cancel();
    _offlineDebounceTimer?.cancel();
    super.dispose();
  }
}

final networkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, bool>((ref) {
  return NetworkStatusNotifier();
});
