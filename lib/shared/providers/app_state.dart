import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const onBoardKey = "app.GD2G82CG9G82VDFGVD22DVG";
const initializedKey = "app.GDSG82CG9G82VDFGVD22DVG";
const isAdminKey = "app.GDSG82CG9G83VDFGVD22DVG";

class AppState extends ChangeNotifier {
  late final SharedPreferences prefs;

  late bool _initialized;
  late bool _onBoarding;

  AppState(this.prefs) {
    _onBoarding = prefs.getBool(onBoardKey) ?? false;
    _initialized = prefs.getBool(initializedKey) ?? false;
  }

  bool get initialized => _initialized;

  bool get onBoarding => _onBoarding;

  set initialized(bool value) {
    _initialized = value;
    notifyListeners();
  }

  set onBoarding(bool value) {
    prefs.setBool(onBoardKey, value);
    _onBoarding = value;
    notifyListeners();
  }

  Future<void> onAppStart() async {
    _onBoarding = prefs.getBool(onBoardKey) ?? false;

    // This is just to demonstrate the splash screen is working.
    // In real-life applications, it is not recommended to interrupt the user experience by doing such things.
    await Future.delayed(const Duration(seconds: 1));

    _initialized = true;
    prefs.setBool(initializedKey, _initialized);
    notifyListeners();
  }
}
