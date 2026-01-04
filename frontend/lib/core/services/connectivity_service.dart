import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;
  
  bool get isOnline => _isOnline;
  
  // Callback when network is restored
  VoidCallback? onNetworkRestored;
  
  ConnectivityService() {
    _init();
  }
  
  void _init() {
    // Check initial status
    _connectivity.checkConnectivity().then((List<ConnectivityResult> results) {
      _updateStatus(results);
    });
    
    // Listen for changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateStatus(results);
    });
  }
  
  void _updateStatus(List<ConnectivityResult> results) {
    final wasOffline = !_isOnline;
    _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    // Trigger sync when coming back online
    if (wasOffline && _isOnline) {
      onNetworkRestored?.call();
    }
    
    notifyListeners();
  }
}
