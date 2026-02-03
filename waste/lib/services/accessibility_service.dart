import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityService {
  static const String _textScaleKey = 'accessibility_text_scale';
  static const String _highContrastKey = 'accessibility_high_contrast';

  static SharedPreferences? _prefs;
  static bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // Text Scale Factor
  Future<void> setTextScaleFactor(double scale) async {
    final prefs = await _getPrefs();
    await prefs.setDouble(_textScaleKey, scale);
  }

  double getTextScaleFactor() {
    return _prefs?.getDouble(_textScaleKey) ?? 1.0;
  }

  Future<double> getTextScaleFactorAsync() async {
    final prefs = await _getPrefs();
    return prefs.getDouble(_textScaleKey) ?? 1.0;
  }

  // High Contrast Mode
  Future<void> setHighContrast(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_highContrastKey, enabled);
  }

  bool isHighContrastEnabled() {
    return _prefs?.getBool(_highContrastKey) ?? false;
  }

  Future<bool> isHighContrastEnabledAsync() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_highContrastKey) ?? false;
  }

  // Color schemes based on contrast mode
  ColorScheme getColorScheme(bool isDarkMode, bool isHighContrast) {
    if (isHighContrast) {
      return isDarkMode
          ? const ColorScheme.dark(
              primary: Colors.white,
              secondary: Colors.yellow,
              surface: Colors.black,
              background: Colors.black,
            )
          : const ColorScheme.light(
              primary: Colors.black,
              secondary: Colors.black,
              surface: Colors.white,
              background: Colors.white,
            );
    }
    return isDarkMode
        ? ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          )
        : ColorScheme.fromSeed(seedColor: Colors.green);
  }

  // Text themes with scale factor
  TextTheme getTextTheme(TextTheme baseTheme, double scaleFactor) {
    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: (baseTheme.displayLarge?.fontSize ?? 32) * scaleFactor,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: (baseTheme.displayMedium?.fontSize ?? 28) * scaleFactor,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: (baseTheme.displaySmall?.fontSize ?? 24) * scaleFactor,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: (baseTheme.headlineLarge?.fontSize ?? 20) * scaleFactor,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: (baseTheme.headlineMedium?.fontSize ?? 18) * scaleFactor,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: (baseTheme.headlineSmall?.fontSize ?? 16) * scaleFactor,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: (baseTheme.titleLarge?.fontSize ?? 16) * scaleFactor,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontSize: (baseTheme.titleMedium?.fontSize ?? 14) * scaleFactor,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontSize: (baseTheme.titleSmall?.fontSize ?? 12) * scaleFactor,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: (baseTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: (baseTheme.bodyMedium?.fontSize ?? 14) * scaleFactor,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: (baseTheme.bodySmall?.fontSize ?? 12) * scaleFactor,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: (baseTheme.labelLarge?.fontSize ?? 14) * scaleFactor,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontSize: (baseTheme.labelMedium?.fontSize ?? 12) * scaleFactor,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontSize: (baseTheme.labelSmall?.fontSize ?? 10) * scaleFactor,
      ),
    );
  }
}
