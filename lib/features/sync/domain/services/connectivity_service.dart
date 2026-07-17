import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'i_sync_service.dart';

class ConnectivityService {
  final ISyncService _syncService;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool _lastOnlineStatus = false;

  ConnectivityService({
    required ISyncService syncService,
    Connectivity? connectivity,
  })  : _syncService = syncService,
        _connectivity = connectivity ?? Connectivity();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool get isCurrentlyOnline => _lastOnlineStatus;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _lastOnlineStatus = _isOnline(results);
    _connectivityController.add(_lastOnlineStatus);

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      final online = _isOnline(results);
      _connectivityController.add(online);

      if (online && !_lastOnlineStatus) {
        debugPrint('[ConnectivityService] Connection restored, triggering sync');
        _onReconnect();
      }

      _lastOnlineStatus = online;
    });
  }

  Future<void> _onReconnect() async {
    try {
      await _syncService.syncPendingRecords();
    } catch (e) {
      debugPrint('[ConnectivityService] Error during reconnect sync: $e');
    }
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
