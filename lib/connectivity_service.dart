// lib/connectivity_service.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  ConnectivityService() {
    // Initial check
    _checkConnectivity();
    
    // Subscribe to stream updates
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Consider online if any connection type is available (not none)
    final newStatus = results.isNotEmpty && !results.every((result) => result == ConnectivityResult.none);
    
    if (_isOnline != newStatus) {
      _isOnline = newStatus;
      debugPrint('🌐 Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      notifyListeners();
      // The QueueProvider will listen for this to trigger resync
    }
  }
}

