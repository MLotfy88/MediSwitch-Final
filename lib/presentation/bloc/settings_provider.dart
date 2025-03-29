import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Import Material for ThemeMode
import 'package:shared_preferences/shared_preferences.dart'; // To persist settings

// Constants for SharedPreferences keys
const String _prefsKeyTheme = 'app_theme_mode';
const String _prefsKeyLanguage = 'app_language_code';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;

  // --- State Variables ---
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme
  Locale _locale = const Locale('ar'); // Default to Arabic
  bool _isInitialized = false;

  // --- Getters ---
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  // Constructor - Load settings asynchronously
  SettingsProvider() {
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeString =
        _prefs.getString(_prefsKeyTheme) ?? ThemeMode.system.name;
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeString,
      orElse: () => ThemeMode.system,
    );

    // Load Language
    final langCode = _prefs.getString(_prefsKeyLanguage) ?? 'ar';
    _locale = Locale(langCode);

    _isInitialized = true;
    notifyListeners(); // Notify listeners once settings are loaded
    print('Settings loaded: Theme=$_themeMode, Locale=$_locale');
  }

  // --- Methods ---

  // Update Theme Mode
  Future<void> updateThemeMode(ThemeMode newThemeMode) async {
    if (_themeMode == newThemeMode) return; // No change needed

    _themeMode = newThemeMode;
    notifyListeners();

    // Persist the setting
    await _prefs.setString(_prefsKeyTheme, newThemeMode.name);
    print('Theme mode updated and saved: $_themeMode');
  }

  // Update Locale
  Future<void> updateLocale(Locale newLocale) async {
    if (_locale == newLocale) return; // No change needed

    _locale = newLocale;
    notifyListeners();

    // Persist the setting
    await _prefs.setString(_prefsKeyLanguage, newLocale.languageCode);
    print('Locale updated and saved: $_locale');
  }
}
