import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/entities/interaction_severity.dart';

class InteractionCard extends StatelessWidget {
  final DrugInteraction interaction;

  const InteractionCard({super.key, required this.interaction});

  // Helper to get color and icon based on severity
  ({Color color, Color backgroundColor, IconData icon, String text})
  _getSeverityStyle(BuildContext context, InteractionSeverity severity) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (severity) {
      case InteractionSeverity.major:
        return (
          color: colorScheme.error,
          backgroundColor: colorScheme.errorContainer.withOpacity(0.3),
          icon: LucideIcons.alertOctagon,
          text: 'شديد',
        );
      case InteractionSeverity.moderate:
        return (
          color: Colors.orange.shade800,
          backgroundColor: Colors.orange.shade100.withOpacity(0.5),
          icon: LucideIcons.alertTriangle,
          text: 'متوسط',
        );
      case InteractionSeverity.minor:
        return (
          color: colorScheme.secondary,
          backgroundColor: colorScheme.secondaryContainer.withOpacity(0.3),
          icon: LucideIcons.info,
          text: 'طفيف',
        );
      default:
        return (
          color: colorScheme.onSurfaceVariant,
          backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
          icon: LucideIcons.helpCircle,
          text: 'غير معروف',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final severityStyle = _getSeverityStyle(context, interaction.severity);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityStyle.color.withOpacity(0.4)),
      ),
      color: severityStyle.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity Header
            Row(
              children: [
                Icon(severityStyle.icon, color: severityStyle.color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'تفاعل ${severityStyle.text} بين:',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: severityStyle.color,
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
            if (interaction.arabicEffect.isNotEmpty) ...[
              Text(
                'التأثير:',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(interaction.arabicEffect, style: textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],
            // Recommendation
            if (interaction.arabicRecommendation.isNotEmpty) ...[
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
            ],
          ],
        ),
      ),
    );
  }
}
