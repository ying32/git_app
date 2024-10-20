import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:git_app/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  AppConfig._();

  static final _instance = AppConfig._();
  static AppConfig get instance => _instance;

  /// 主题模式
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode value) {
    if (themeMode == value) return;
    _themeMode = value;
    _update('theme_mode', value);
  }

  Future<void> _update(String name, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    switch (value.runtimeType) {
      case int:
        prefs.setInt(name, value);
      case bool:
        prefs.setBool(name, value);
      case String:
        prefs.setString(name, value);
      case double:
        prefs.setDouble(name, value);
      default:
        if (value is Enum) {
          prefs.setInt(name, value.index);
        } else {
          if (kDebugMode) {
            print("name=${value.runtimeType}");
          }
        }
    }
  }

  Future<void> readConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = enumFromValue(
          ThemeMode.values, prefs.getInt('theme_mode') ?? 0, ThemeMode.light);
    } catch (e) {
      if (kDebugMode) {
        print("readConfig error: $e");
      }
    }
  }
}
