import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

class InteractionCard extends StatelessWidget {
  final DrugInteraction interaction;

  const InteractionCard({super.key, required this.interaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: appColors.shadowCard,
        border: Border.all(
          color: _getSeverityColor(
            interaction.severity,
            appColors,
          ).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Severity and Drugs
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getSeverityColor(
                interaction.severity,
                appColors,
              ).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSeverityIcon(interaction.severity),
                  color: _getSeverityColor(interaction.severity, appColors),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSeverityLabel(interaction.severity),
                    style: TextStyle(
                      color: _getSeverityColor(interaction.severity, appColors),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Interaction Description (Use effect from entity)
                Text(
                  interaction.effect,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                if (interaction.recommendation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.stethoscope,
                        size: 16,
                        color: appColors.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          interaction.recommendation,
                          style: TextStyle(
                            color: appColors.mutedForeground,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(
    InteractionSeverity severity,
    AppColorsExtension appColors,
  ) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
      case InteractionSeverity.severe:
        return appColors.dangerForeground; // Use foreground for better contrast
      case InteractionSeverity.major:
        return Colors
            .orange; // Assuming orange isn't in appColors or using warning
      case InteractionSeverity.moderate:
        return appColors.warningForeground;
      case InteractionSeverity.minor:
        return appColors.infoForeground;
      case InteractionSeverity.unknown:
      default:
        return appColors.mutedForeground;
    }
  }

  IconData _getSeverityIcon(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return LucideIcons.ban;
      case InteractionSeverity.severe:
        return LucideIcons.alertOctagon;
      case InteractionSeverity.major:
        return LucideIcons.alertTriangle;
      case InteractionSeverity.moderate:
        return LucideIcons.alertCircle;
      case InteractionSeverity.minor:
        return LucideIcons.info;
      case InteractionSeverity.unknown:
      default:
        return LucideIcons.helpCircle;
    }
  }

  String _getSeverityLabel(InteractionSeverity severity) {
    // Localization can be added here
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return 'Contraindicated';
      case InteractionSeverity.severe:
        return 'Severe Interaction';
      case InteractionSeverity.major:
        return 'Major Interaction';
      case InteractionSeverity.moderate:
        return 'Moderate Interaction';
      case InteractionSeverity.minor:
        return 'Minor Interaction';
      case InteractionSeverity.unknown:
      default:
        return 'Unknown Severity';
    }
  }
}
