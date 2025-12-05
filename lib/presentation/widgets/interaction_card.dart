import 'package:flutter/material.dart';
import '../../domain/entities/drug_interaction.dart';
import 'helpers/interaction_severity_helper.dart';

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
    final severityBg = InteractionSeverityHelper.getSeverityBackgroundColor(
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
        side: BorderSide(color: severityColor.withOpacity(0.4)),
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
                  isArabic
                      ? 'تفاعل $severityLabel بين:'
                      : '$severityLabel Interaction:',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
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
                ),
              ),
              const SizedBox(height: 4),
              Text(interaction.arabicEffect, style: textTheme.bodyMedium),
              const SizedBox(height: 12),
            ] else if (interaction.effect.isNotEmpty) ...[
              Text(
                isArabic ? 'وصف التفاعل:' : 'Effect:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(interaction.effect, style: textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],

            // Recommendation
            if (isArabic && interaction.arabicRecommendation.isNotEmpty) ...[
              Text(
                'التوصية:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                interaction.arabicRecommendation,
                style: textTheme.bodyMedium,
              ),
            ] else if (interaction.recommendation.isNotEmpty) ...[
              Text(
                isArabic ? 'التوصية الطبية:' : 'Recommendation:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(interaction.recommendation, style: textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
