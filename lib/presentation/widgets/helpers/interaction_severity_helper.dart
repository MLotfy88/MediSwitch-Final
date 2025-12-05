import 'package:flutter/material.dart';
import '../../../domain/entities/drug_interaction.dart';
import '../../../domain/entities/interaction_severity.dart';

/// Helper class for interaction severity visualization
class InteractionSeverityHelper {
  /// Get color for severity level
  static Color getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return const Color(0xFFDC2626); // Red 600
      case InteractionSeverity.severe:
        return const Color(0xFFEA580C); // Orange 600
      case InteractionSeverity.major:
        return const Color(0xFFF59E0B); // Amber 500
      case InteractionSeverity.moderate:
        return const Color(0xFFFBBF24); // Yellow 400
      case InteractionSeverity.minor:
        return const Color(0xFF10B981); // Green 500
      case InteractionSeverity.unknown:
        return const Color(0xFF6B7280); // Gray 500
    }
  }

  /// Get background color for severity (lighter variant)
  static Color getSeverityBackgroundColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return const Color(0xFFFEE2E2); // Red 100
      case InteractionSeverity.severe:
        return const Color(0xFFFFEDD5); // Orange 100
      case InteractionSeverity.major:
        return const Color(0xFFFEF3C7); // Amber 100
      case InteractionSeverity.moderate:
        return const Color(0xFFFEF9C3); // Yellow 100
      case InteractionSeverity.minor:
        return const Color(0xFFD1FAE5); // Green 100
      case InteractionSeverity.unknown:
        return const Color(0xFFF3F4F6); // Gray 100
    }
  }

  /// Get icon for severity level
  static IconData getSeverityIcon(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return Icons.dangerous;
      case InteractionSeverity.severe:
        return Icons.warning;
      case InteractionSeverity.major:
        return Icons.error_outline;
      case InteractionSeverity.moderate:
        return Icons.info_outline;
      case InteractionSeverity.minor:
        return Icons.check_circle_outline;
      case InteractionSeverity.unknown:
        return Icons.help_outline;
    }
  }

  /// Get Arabic label for severity
  static String getSeverityLabelAr(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return 'ممنوع';
      case InteractionSeverity.severe:
        return 'شديد';
      case InteractionSeverity.major:
        return 'كبير';
      case InteractionSeverity.moderate:
        return 'متوسط';
      case InteractionSeverity.minor:
        return 'بسيط';
      case InteractionSeverity.unknown:
        return 'غير معروف';
    }
  }

  /// Get English label for severity
  static String getSeverityLabelEn(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return 'Contraindicated';
      case InteractionSeverity.severe:
        return 'Severe';
      case InteractionSeverity.major:
        return 'Major';
      case InteractionSeverity.moderate:
        return 'Moderate';
      case InteractionSeverity.minor:
        return 'Minor';
      case InteractionSeverity.unknown:
        return 'Unknown';
    }
  }
}
