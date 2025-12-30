import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

/// A card that displays information about a drug-drug or drug-food interaction.
class InteractionCard extends StatelessWidget {
  /// The interaction data to display.
  final DrugInteraction interaction;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Whether to show the full details (effect, recommendation).
  /// Defaults to true. If false, shows a compact version.
  final bool showDetails;

  /// Creates a new [InteractionCard] instance.
  const InteractionCard({
    required this.interaction,
    super.key,
    this.onTap,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final colorScheme = theme.colorScheme;
    final severityColor = _getSeverityColor(
      interaction.severityEnum,
      appColors,
    );
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final effect =
        isRTL
            ? (interaction.arabicEffect ?? interaction.effect ?? '')
            : (interaction.effect ?? '');
    final recommendation =
        isRTL
            ? (interaction.arabicRecommendation ??
                interaction.recommendation ??
                '')
            : (interaction.recommendation ?? '');

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: appColors.border.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row with circular icon and severity label + ingredients
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular icon container
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
                  // Ingredients and severity label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${interaction.ingredient1} + '
                          '${interaction.ingredient2}',
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

              if (showDetails) ...[
                // Interaction Effect
                if (effect.isNotEmpty)
                  Text(
                    effect,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                if (recommendation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: severityColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRTL ? 'التوصية:' : 'Recommendation:',
                          style: TextStyle(
                            color: severityColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),

                if (effect.isEmpty && recommendation.isEmpty)
                  Text(
                    isRTL ? 'لا توجد تفاصيل متاحة.' : 'No details available.',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ] else ...[
                // Compact Mode Hint
                Row(
                  children: [
                    Text(
                      isRTL ? 'اضغط لعرض التفاصيل' : 'Tap for details',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isRTL ? LucideIcons.arrowLeft : LucideIcons.arrowRight,
                      size: 14,
                      color: theme.colorScheme.primary.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
        return Colors.orange;
      case InteractionSeverity.moderate:
        return appColors.warningForeground;
      case InteractionSeverity.minor:
        return appColors.infoForeground;
      case InteractionSeverity.unknown:
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
        return 'Unknown Severity';
    }
  }
}
