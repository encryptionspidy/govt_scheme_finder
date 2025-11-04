import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider() {
    _init();
  }

  ConnectivityResult _status = ConnectivityResult.none;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityResult get status => _status;
  bool get isOnline => _status != ConnectivityResult.none;

  Future<void> _init() async {
    final Connectivity connectivity = Connectivity();
    final List<ConnectivityResult> current = await connectivity.checkConnectivity();
    _status = current.isNotEmpty ? current.first : ConnectivityResult.none;
    notifyListeners();
    _subscription = connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final ConnectivityResult next = results.isNotEmpty ? results.first : ConnectivityResult.none;
      if (_status != next) {
        _status = next;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
