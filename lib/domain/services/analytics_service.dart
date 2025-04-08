/// Abstract class defining the contract for the Analytics Service.
abstract class AnalyticsService {
  /// Logs an analytics event.
  ///
  /// [eventType] is a string identifying the type of event (e.g., 'search', 'screen_view', 'feature_use').
  /// [data] is an optional map containing additional details about the event.
  Future<void> logEvent(String eventType, {Map<String, dynamic>? data});

  // Potential future methods:
  // Future<void> setUserProperties(Map<String, dynamic> properties);
  // Future<void> setUserId(String userId);
}
