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
    final severityColor = _getSeverityColor(
      interaction.severityEnum,
      appColors,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: appColors.shadowCard,
        border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with circular icon and severity label + interacting drug name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular icon container (w-10 h-10 rounded-full)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getSeverityIcon(interaction.severityEnum),
                    color: severityColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Drug name and severity label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Interacting drug name (font-semibold)
                    Text(
                      interaction.interactionDrugName,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Severity label badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getSeverityLabel(interaction.severityEnum),
                        style: TextStyle(
                          color: severityColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Interaction Description
          if (interaction.description != null &&
              interaction.description!.isNotEmpty)
            Text(
              interaction.description!,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.5,
              ),
            )
          else
            Text(
              "No details available.",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),

          // Removed Recommendation box as it's no longer separate field
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
