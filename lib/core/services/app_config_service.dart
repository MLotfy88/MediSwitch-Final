import 'package:mediswitch/core/constants/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage application configuration settings
class AppConfigService {
  final SharedPreferences _prefs;

  AppConfigService(this._prefs);

  // ==================== Badge Configuration ====================

  /// Get the limit for NEW drugs badge
  int get newDrugsLimit {
    return _prefs.getInt(AppConfig.keyNewDrugsLimit) ??
        AppConfig.defaultNewDrugsLimit;
  }

  /// Set the limit for NEW drugs badge
  Future<bool> setNewDrugsLimit(int limit) async {
    if (limit < AppConfig.minNewDrugsLimit ||
        limit > AppConfig.maxNewDrugsLimit) {
      throw ArgumentError(
        'New drugs limit must be between ${AppConfig.minNewDrugsLimit} '
        'and ${AppConfig.maxNewDrugsLimit}',
      );
    }
    return await _prefs.setInt(AppConfig.keyNewDrugsLimit, limit);
  }

  /// Get the limit for POPULAR drugs badge
  int get popularDrugsLimit {
    return _prefs.getInt(AppConfig.keyPopularDrugsLimit) ??
        AppConfig.defaultPopularDrugsLimit;
  }

  /// Set the limit for POPULAR drugs badge
  Future<bool> setPopularDrugsLimit(int limit) async {
    if (limit < AppConfig.minPopularDrugsLimit ||
        limit > AppConfig.maxPopularDrugsLimit) {
      throw ArgumentError(
        'Popular drugs limit must be between ${AppConfig.minPopularDrugsLimit} '
        'and ${AppConfig.maxPopularDrugsLimit}',
      );
    }
    return await _prefs.setInt(AppConfig.keyPopularDrugsLimit, limit);
  }

  /// Reset badge limits to default values
  Future<void> resetBadgeLimits() async {
    await _prefs.remove(AppConfig.keyNewDrugsLimit);
    await _prefs.remove(AppConfig.keyPopularDrugsLimit);
  }

  /// Get all badge configuration as a map
  Map<String, int> getBadgeConfig() {
    return {
      'newDrugsLimit': newDrugsLimit,
      'popularDrugsLimit': popularDrugsLimit,
    };
  }
}
