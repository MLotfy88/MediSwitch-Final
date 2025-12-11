import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';

// Constants for SharedPreferences keys
const String _prefsKeyTheme = 'app_theme_mode';
const String _prefsKeyLanguage = 'app_language_code';
const String _prefsKeyPushNotifications = 'push_notifications';
const String _prefsKeyPriceAlerts = 'price_alerts';
const String _prefsKeyNewDrugAlerts = 'new_drug_alerts';
const String _prefsKeyInteractionAlerts = 'interaction_alerts';
const String _prefsKeySoundEffects = 'sound_effects';
const String _prefsKeyHapticFeedback = 'haptic_feedback';
const String _prefsKeyFontSize = 'font_size';
const String _prefsKeyOfflineMode = 'offline_mode';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  final FileLoggerService _logger = locator<FileLoggerService>();

  // --- State Variables ---
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en'); // Default to English
  bool _isInitialized = false;

  // Notification settings
  bool _pushNotificationsEnabled = true;
  bool _priceAlertsEnabled = true;
  bool _newDrugAlertsEnabled = false;
  bool _interactionAlertsEnabled = true;

  // Sound & Haptics settings
  bool _soundEffectsEnabled = true;
  bool _hapticFeedbackEnabled = true;

  // Appearance settings
  double _fontSize = 16.0;

  // Data settings
  bool _offlineModeEnabled = false;

  // --- Getters ---
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get priceAlertsEnabled => _priceAlertsEnabled;
  bool get newDrugAlertsEnabled => _newDrugAlertsEnabled;
  bool get interactionAlertsEnabled => _interactionAlertsEnabled;
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  double get fontSize => _fontSize;
  bool get offlineModeEnabled => _offlineModeEnabled;

  // Constructor
  SettingsProvider() {
    _logger.i("SettingsProvider: Constructor called.");
    _loadSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    _logger.i("SettingsProvider: _loadSettings started.");
    _prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeString =
        _prefs.getString(_prefsKeyTheme) ?? ThemeMode.system.name;
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeString,
      orElse: () => ThemeMode.system,
    );

    // Load Language
    final langCode =
        _prefs.getString(_prefsKeyLanguage) ?? 'en'; // Default 'en'
    _locale = Locale(langCode);

    // Load Notification settings
    _pushNotificationsEnabled =
        _prefs.getBool(_prefsKeyPushNotifications) ?? true;
    _priceAlertsEnabled = _prefs.getBool(_prefsKeyPriceAlerts) ?? true;
    _newDrugAlertsEnabled = _prefs.getBool(_prefsKeyNewDrugAlerts) ?? false;
    _interactionAlertsEnabled =
        _prefs.getBool(_prefsKeyInteractionAlerts) ?? true;

    // Load Sound & Haptics settings
    _soundEffectsEnabled = _prefs.getBool(_prefsKeySoundEffects) ?? true;
    _hapticFeedbackEnabled = _prefs.getBool(_prefsKeyHapticFeedback) ?? true;

    // Load Appearance settings
    _fontSize = _prefs.getDouble(_prefsKeyFontSize) ?? 16.0;

    // Load Data settings
    _offlineModeEnabled = _prefs.getBool(_prefsKeyOfflineMode) ?? false;

    _isInitialized = true;
    notifyListeners();
    _logger.i('Settings loaded: Theme=$_themeMode, Locale=$_locale');
  }

  // --- Methods ---

  Future<void> updateThemeMode(ThemeMode newThemeMode) async {
    if (_themeMode == newThemeMode) return;
    _themeMode = newThemeMode;
    notifyListeners();
    await _prefs.setString(_prefsKeyTheme, newThemeMode.name);
    _logger.i('Theme mode updated: $_themeMode');
  }

  Future<void> updateLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    await _prefs.setString(_prefsKeyLanguage, newLocale.languageCode);
    _logger.i('Locale updated: $_locale');
  }

  // Notification settings
  Future<void> updatePushNotifications(bool value) async {
    _pushNotificationsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_prefsKeyPushNotifications, value);
  }

  Future<void> updatePriceAlerts(bool value) async {
    _priceAlertsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_prefsKeyPriceAlerts, value);
  }

  Future<void> updateNewDrugAlerts(bool value) async {
    _newDrugAlertsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_prefsKeyNewDrugAlerts, value);
  }

  Future<void> updateInteractionAlerts(bool value) async {
    _interactionAlertsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_prefsKeyInteractionAlerts, value);
  }

  // Sound & Haptics settings
  Future<void> updateSoundEffects(bool value) async {
    _soundEffectsEnabled = value;
    notifyListeners();
    await _prefs.setBool(_prefsKeySoundEffects, value);
  }

  Future<void> updateHapticFeedback(bool value) async {
    _hapticFeedbackEnabled = value;
    notifyListeners();
    await _prefs.setBool(_prefsKeyHapticFeedback, value);
  }

  // Appearance settings
  Future<void> updateFontSize(double value) async {
    _fontSize = value;
    notifyListeners();
    await _prefs.setDouble(_prefsKeyFontSize, value);
  }

  // Data settings
  Future<void> updateOfflineMode(bool value) async {
    _offlineModeEnabled = value;
    notifyListeners();
    await _prefs.setBool(_prefsKeyOfflineMode, value);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _prefs.clear();
    _logger.i('All data cleared');
    // Reset to defaults
    _themeMode = ThemeMode.system;
    _locale = const Locale('en'); // Reset to English
    _pushNotificationsEnabled = true;
    _priceAlertsEnabled = true;
    _newDrugAlertsEnabled = false;
    _interactionAlertsEnabled = true;
    _soundEffectsEnabled = true;
    _hapticFeedbackEnabled = true;
    _fontSize = 16.0;
    _offlineModeEnabled = false;
    notifyListeners();
  }
}
