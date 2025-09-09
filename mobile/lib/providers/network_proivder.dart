import 'dart:async';

import 'package:freshk/utils/navigation_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkProvider with ChangeNotifier {
  bool _isOnline = true;
  bool _hasShownNoNetworkScreen = false;
  bool _isNavigating = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  bool get isOnline => _isOnline;
  bool get hasShownNoNetworkScreen => _hasShownNoNetworkScreen;
  bool get isNavigating => _isNavigating;

  NetworkProvider() {
    _initializeNetworkMonitoring();
  }

  void _initializeNetworkMonitoring() {
    final connectivity = Connectivity();

    // Check initial connectivity
    connectivity.checkConnectivity().then((res) {
      _updateConnectivityStatus(res);
    }).catchError((error) {
      debugPrint('Error checking initial connectivity: $error');
      _setOfflineStatus();
    });

    // Listen for connectivity changes
    _connectivitySubscription = connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      _updateConnectivityStatus(result);
    });
  }

  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final bool hasConnection =
        results.any((result) => result != ConnectivityResult.none);

    if (hasConnection && !_isOnline) {
      // Coming back online
      _setOnlineStatus();
      if (_hasShownNoNetworkScreen) {
        _dismissNoNetworkScreen();
      }
    } else if (!hasConnection && _isOnline) {
      // Going offline
      _setOfflineStatus();
      _showNoNetworkScreen();
    }
  }

  void _setOnlineStatus() {
    _isOnline = true;
    notifyListeners();
    debugPrint('✅ Network: Back online');
  }

  void _setOfflineStatus() {
    _isOnline = false;
    notifyListeners();
    debugPrint('❌ Network: Offline');
  }

  void _showNoNetworkScreen() {
    if (!_hasShownNoNetworkScreen && !_isNavigating) {
      _hasShownNoNetworkScreen = true;
      _isNavigating = true;

      // Delay navigation to ensure UI is ready
      Future.microtask(() {
        final currentRoute = NavigationService.getCurrentRouteName();
        // Don't show no network screen if already on splash, login, or noNetwork
        if (currentRoute != '/splash' &&
            currentRoute != '/login' &&
            currentRoute != '/noNetwork' &&
            currentRoute != '/' &&
            !_isNavigating) {
          NavigationService.navigateToNoNetwork();
        }
        _isNavigating = false;
      });
    }
  }

  void _dismissNoNetworkScreen() {
    if (_hasShownNoNetworkScreen && !_isNavigating) {
      _hasShownNoNetworkScreen = false;
      _isNavigating = true;

      // Only pop if we're actually on the no network screen
      final currentRoute = NavigationService.getCurrentRouteName();
      if (currentRoute == '/noNetwork') {
        NavigationService.popRoute();
      }

      Future.delayed(const Duration(milliseconds: 300), () {
        _isNavigating = false;
      });
    }
  }

  // Manual retry method for the UI
  Future<bool> checkConnectivity() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      _updateConnectivityStatus(result);
      return _isOnline;
    } catch (e) {
      debugPrint('Error during manual connectivity check: $e');
      return false;
    }
  }

  // Reset the no network screen flag (useful for navigation edge cases)
  void resetNoNetworkScreenFlag() {
    _hasShownNoNetworkScreen = false;
    _isNavigating = false;
  }

  // Manually set network state (useful for testing or edge cases)
  void setNetworkState(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
