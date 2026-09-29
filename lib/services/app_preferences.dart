import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  AppPreferences._();

  static final AppPreferences instance = AppPreferences._();

  static const String _themeModeKey = 'theme_mode';

  final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync();

  Future<ThemeMode> getThemeMode() async {
    final value =
        await _preferences.getString(_themeModeKey);

    switch (value) {
      case 'light':
        return ThemeMode.light;

      case 'dark':
        return ThemeMode.dark;

      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };

    await _preferences.setString(
      _themeModeKey,
      value,
    );
  }
}