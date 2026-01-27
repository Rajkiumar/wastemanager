import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app-wide theme mode with simple persistence.
class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _key = 'theme_mode';
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    switch (saved) {
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      case 'system':
        themeMode.value = ThemeMode.system;
        break;
      default:
        themeMode.value = ThemeMode.light;
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, enabled ? 'dark' : 'light');
  }

  bool get isDark => themeMode.value == ThemeMode.dark;
}
