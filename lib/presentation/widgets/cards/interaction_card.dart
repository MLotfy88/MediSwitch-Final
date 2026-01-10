import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

/// A card that displays information about a drug-drug or drug-food interaction.
class InteractionCard extends StatelessWidget {
  /// Creates a new [InteractionCard] instance.
  const InteractionCard({
    required this.interaction,
    super.key,
    this.onTap,
    this.showDetails = true,
  });

  /// The interaction data to display.
  final DrugInteraction interaction;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Whether to show the full details (effect, recommendation).
  /// Defaults to true. If false, shows a compact version.
  final bool showDetails;

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

    final isFood = interaction.type == 'food';
    final isDisease = interaction.type == 'disease';

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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Severity Icon Indicator
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        isFood
                            ? LucideIcons.apple
                            : (isDisease
                                ? LucideIcons.activity
                                : _getSeverityIcon(interaction.severityEnum)),
                        color: severityColor,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ingredients / Target
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDisease
                              ? '${interaction.ingredient1} + ${interaction.ingredient2}'
                              : (isFood
                                  ? (effect.isNotEmpty
                                      ? effect
                                      : '${interaction.ingredient1} + ${isRTL ? 'طعام' : 'Food'}')
                                  : '${interaction.ingredient1} + ${interaction.ingredient2}'),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // Small Severity Dot + Label
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: severityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getSeverityLabel(
                                interaction.severityEnum,
                                isRTL,
                              ),
                              style: TextStyle(
                                color: severityColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!showDetails)
                    Icon(
                      isRTL
                          ? LucideIcons.chevronLeft
                          : LucideIcons.chevronRight,
                      size: 16,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                ],
              ),
              if (showDetails) ...[
                const SizedBox(height: 12),
                // Interaction Effect
                if (effect.isNotEmpty)
                  Text(
                    effect,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                if (recommendation.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: severityColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.shieldAlert,
                              size: 14,
                              color: severityColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isRTL ? 'التوصية الطبية' : 'Recommendation',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: severityColor,
                              ),
                            ),
                          ],
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

                // Mechanism (Scientific Explanation)
                if (interaction.mechanismText != null &&
                    interaction.mechanismText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  // Mechanism
                  _SectionTitle(
                    title: isRTL ? 'الآلية العلمية' : 'Mechanism',
                    icon: LucideIcons.microscope,
                    color: Colors.purple,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    interaction.mechanismText!,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],

                // Clinical Management (Actionable Advice)
                if (interaction.managementText != null &&
                    interaction.managementText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionTitle(
                    title:
                        isRTL ? 'الإجراء الطبي المقترح' : 'Clinical Management',
                    icon: LucideIcons.stethoscope,
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    interaction.managementText!,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
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
        return const Color(0xFF8B0000); // Deep Dark Red
      case InteractionSeverity.severe:
        return AppColors.danger; // Standard Red
      case InteractionSeverity.major:
        return Colors.orange[900]!; // Dark Orange/Brown
      case InteractionSeverity.moderate:
        return Colors.orange[400]!; // Lighter Orange
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

  String _getSeverityLabel(InteractionSeverity severity, bool isRTL) {
    // Localization can be added here
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return isRTL ? 'ممنوع' : 'CI';
      case InteractionSeverity.severe:
        return isRTL ? 'شديد' : 'Severe';
      case InteractionSeverity.major:
        return isRTL ? 'هام' : 'Major';
      case InteractionSeverity.moderate:
        return isRTL ? 'متوسط' : 'Moderate';
      case InteractionSeverity.minor:
        return isRTL ? 'طفيف' : 'Minor';
      case InteractionSeverity.unknown:
        return isRTL ? 'غير محدد' : 'N/A';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
