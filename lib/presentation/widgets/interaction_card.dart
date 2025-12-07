import 'package:flutter/material.dart';

import '../../domain/entities/drug_interaction.dart';
import '../../domain/entities/interaction_severity.dart';
import 'helpers/interaction_severity_helper.dart';
import 'modern_badge.dart';

class InteractionCard extends StatelessWidget {
  final DrugInteraction interaction;

  const InteractionCard({super.key, required this.interaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Use InteractionSeverityHelper for consistent styling
    final severityColor = InteractionSeverityHelper.getSeverityColor(
      interaction.severity,
    );

    // Adjust background for Dark Mode to ensure readability
    final bool isDark = theme.brightness == Brightness.dark;
    final severityBg =
        isDark
            ? severityColor.withOpacity(0.15)
            : InteractionSeverityHelper.getSeverityBackgroundColor(
              interaction.severity,
            );

    final severityIcon = InteractionSeverityHelper.getSeverityIcon(
      interaction.severity,
    );
    final severityLabel =
        isArabic
            ? InteractionSeverityHelper.getSeverityLabelAr(interaction.severity)
            : InteractionSeverityHelper.getSeverityLabelEn(
              interaction.severity,
            );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withOpacity(isDark ? 0.3 : 0.4)),
      ),
      color: severityBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity Header
            Row(
              children: [
                Icon(severityIcon, color: severityColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'تفاعل بين:' : 'Interaction:',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
                const SizedBox(width: 8),
                // Severity Badge
                ModernBadge(
                  text: severityLabel.toUpperCase(),
                  variant: _getSeverityBadgeVariant(interaction.severity),
                  size: BadgeSize.sm,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Interacting Ingredients
            Text(
              '• ${interaction.ingredient1}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              '• ${interaction.ingredient2}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const Divider(height: 24, thickness: 0.5),
            // Effect/Description
            if (isArabic && interaction.arabicEffect.isNotEmpty) ...[
              Text(
                'التأثير:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                interaction.arabicEffect,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
            ] else if (interaction.effect.isNotEmpty) ...[
              Text(
                isArabic ? 'وصف التفاعل:' : 'Effect:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                interaction.effect,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Recommendation
            if (isArabic && interaction.arabicRecommendation.isNotEmpty) ...[
              Text(
                'التوصية:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                interaction.arabicRecommendation,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ] else if (interaction.recommendation.isNotEmpty) ...[
              Text(
                isArabic ? 'التوصية الطبية:' : 'Recommendation:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                interaction.recommendation,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get badge variant based on severity level
  BadgeVariant _getSeverityBadgeVariant(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.major:
      case InteractionSeverity.severe:
      case InteractionSeverity.contraindicated:
        return BadgeVariant.danger;
      case InteractionSeverity.moderate:
        return BadgeVariant.warning;
      case InteractionSeverity.minor:
        return BadgeVariant.info;
      case InteractionSeverity.unknown:
        return BadgeVariant.secondary;
    }
  }
}
