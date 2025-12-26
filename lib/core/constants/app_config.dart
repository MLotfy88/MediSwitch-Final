/// Default configuration values for the application
class AppConfig {
  // Badge Configuration
  static const int defaultNewDrugsLimit = 250;
  static const int defaultPopularDrugsLimit = 500;

  // Validation limits
  static const int minNewDrugsLimit = 10;
  static const int maxNewDrugsLimit = 1000;
  static const int minPopularDrugsLimit = 50;
  static const int maxPopularDrugsLimit = 2000;

  // SharedPreferences keys
  static const String keyNewDrugsLimit = 'new_drugs_limit';
  static const String keyPopularDrugsLimit = 'popular_drugs_limit';
}
