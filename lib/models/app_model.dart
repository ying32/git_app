import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class AppModel extends ChangeNotifier {
  AppModel(this._themeMode);
  // Color _themeColor = Colors.green;
  // Color get themeColor => _themeColor;
  // set themeColor(Color value) {
  //   if (value != _themeColor) {
  //     _themeColor = value;
  //     notifyListeners();
  //   }
  // }

  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (value != _themeMode) {
      _themeMode = value;
      notifyListeners();
    }
  }
}
