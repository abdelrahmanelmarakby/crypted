import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

/// Controls app-wide theme mode (light / dark / system).
///
/// Mirrors the [MyLocaleController] pattern:
///   • Persists the choice via [SharedPreferences]
///   • Exposes a reactive [themeMode] observable
///   • Applies changes through [Get.changeThemeMode]
class ThemeController extends GetxController {
  static const String _prefsKey = 'theme_mode';

  /// Current theme mode – defaults to system.
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }

  // ── Persistence ──────────────────────────────────

  /// Load the saved theme mode from disk.
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (saved != null) {
        themeMode.value = _fromString(saved);
        Get.changeThemeMode(themeMode.value);
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  /// Persist the given [mode] and apply it globally.
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _toString(mode));

      themeMode.value = mode;
      Get.changeThemeMode(mode);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  /// Cycle: system → light → dark → system
  Future<void> toggleTheme() async {
    switch (themeMode.value) {
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
    }
  }

  // ── Convenience getters ──────────────────────────

  bool get isDark => themeMode.value == ThemeMode.dark;
  bool get isLight => themeMode.value == ThemeMode.light;
  bool get isSystem => themeMode.value == ThemeMode.system;

  String get currentLabel {
    switch (themeMode.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  // ── Serialisation helpers ────────────────────────

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
