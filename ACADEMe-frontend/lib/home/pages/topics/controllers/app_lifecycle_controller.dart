import 'package:flutter/material.dart';

// App lifecycle manager to track app state
class AppLifecycleController extends WidgetsBindingObserver {
  static final AppLifecycleController _instance = AppLifecycleController._internal();
  factory AppLifecycleController() => _instance;
  AppLifecycleController._internal();

  bool _isAppJustOpened = true;
  DateTime? _lastPausedTime;

  bool get isAppJustOpened => _isAppJustOpened;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _lastPausedTime = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        if (_lastPausedTime != null &&
            DateTime.now().difference(_lastPausedTime!) > const Duration(minutes: 5)) {
          _isAppJustOpened = true;
        }
        break;
      default:
        break;
    }
  }

  void markAsUsed() {
    _isAppJustOpened = false;
  }
}