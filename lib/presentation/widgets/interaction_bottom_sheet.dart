import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';

/// Completely redesigned interaction details bottom sheet
/// Features:
/// - Medical-grade premium design
/// - Automatic RECOMMENDATION extraction from text (enhanced logic)
/// - Severity-aware color theming
/// - RTL support for Arabic
/// - Professional UI for medical experts
class InteractionBottomSheet extends StatelessWidget {
  const InteractionBottomSheet({super.key, required this.interaction});

  final DrugInteraction interaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final isDark = theme.brightness == Brightness.dark;

    final isFood = interaction.type == 'food';
    final isDisease = interaction.type == 'disease';

    final severityColor = _getSeverityColor(interaction.severityEnum);
    final severityIcon = _getSeverityIcon(interaction.severityEnum);
    final severityBgColor = severityColor.withOpacity(isDark ? 0.15 : 0.08);

    // Parse sections from text
    final parsedContent = _parseInteractionContent(interaction, isRTL);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ═══════════════════════════════════════════════════════════
          // HEADER: Drag Handle + Severity Badge
          // ═══════════════════════════════════════════════════════════
          _buildHeader(
            context,
            theme,
            isRTL,
            isFood,
            isDisease,
            severityColor,
            severityIcon,
            severityBgColor,
          ),

          // ═══════════════════════════════════════════════════════════
          // CONTENT: Scrollable Sections
          // ═══════════════════════════════════════════════════════════
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interaction Pair Card
                  // Added extra spacing from header as requested
                  const SizedBox(height: 12),
                  _InteractionPairCard(
                    theme: theme,
                    agent1: interaction.ingredient1,
                    agent2: interaction.ingredient2,
                    isFood: isFood,
                    isRTL: isRTL,
                    severityColor: severityColor,
                  ),

                  const SizedBox(height: 24),

                  // ─── CLINICAL EFFECT ───
                  if (parsedContent.effect.isNotEmpty)
                    _InfoSection(
                      theme: theme,
                      title: isRTL ? 'التأثير السريري' : 'Clinical Effect',
                      icon: LucideIcons.activity,
                      content: parsedContent.effect,
                      accentColor: AppColors.info,
                      isRTL: isRTL,
                    ),

                  // ─── MECHANISM ───
                  if (parsedContent.mechanism.isNotEmpty)
                    _InfoSection(
                      theme: theme,
                      title: isRTL ? 'آلية التفاعل' : 'Mechanism',
                      icon: LucideIcons.dna,
                      content: parsedContent.mechanism,
                      accentColor: AppColors.secondary,
                      isRTL: isRTL,
                    ),

                  // ─── MANAGEMENT / RECOMMENDATION ───
                  if (parsedContent.management.isNotEmpty)
                    _InfoSection(
                      theme: theme,
                      title:
                          isRTL ? 'التوصية الطبية' : 'Clinical Recommendation',
                      icon: LucideIcons.shieldCheck,
                      content: parsedContent.management,
                      accentColor: AppColors.success,
                      isRTL: isRTL,
                      isHighlighted: true,
                    ),

                  // ─── ALTERNATIVES ───
                  if ((interaction.alternativesA != null &&
                          interaction.alternativesA!.isNotEmpty) ||
                      (interaction.alternativesB != null &&
                          interaction.alternativesB!.isNotEmpty))
                    _AlternativesSection(
                      theme: theme,
                      agent1: interaction.ingredient1,
                      alternatives1: interaction.alternativesA,
                      agent2: interaction.ingredient2,
                      alternatives2: interaction.alternativesB,
                      isRTL: isRTL,
                    ),

                  // ─── METADATA CHIPS ───
                  if (interaction.riskLevel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _MetadataChip(
                            label: isRTL ? 'مستوى الخطر' : 'Risk Level',
                            value: interaction.riskLevel!,
                            icon: LucideIcons.gauge,
                            color: severityColor,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════
          // FOOTER: Action Button
          // ═══════════════════════════════════════════════════════════
          _buildFooter(context, theme, isRTL, severityColor),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    bool isRTL,
    bool isFood,
    bool isDisease,
    Color severityColor,
    IconData severityIcon,
    Color severityBgColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: severityBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              // Type + Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFood
                                ? (isRTL ? 'تفاعل غذائي' : 'Food')
                                : (isDisease
                                    ? (isRTL ? 'تحذير مرضي' : 'Disease')
                                    : (isRTL ? 'تفاعل دوائي' : 'Drug')),
                            style: TextStyle(
                              color: severityColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isFood
                              ? LucideIcons.apple
                              : (isDisease
                                  ? LucideIcons.activity
                                  : LucideIcons.pill),
                          size: 14,
                          color: severityColor.withOpacity(0.7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isRTL ? 'تحليل التفاعل الدوائي' : 'Interaction Analysis',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: severityColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              // Severity Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: severityColor.withOpacity(0.25)),
                ),
                child: Column(
                  children: [
                    Icon(severityIcon, color: severityColor, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      _getSeverityLabel(interaction.severityEnum, isRTL),
                      style: TextStyle(
                        color: severityColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    ThemeData theme,
    bool isRTL,
    Color severityColor,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.checkCircle, size: 18),
              const SizedBox(width: 8),
              Text(
                isRTL ? 'تم الاطلاع' : 'Understood',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CONTENT PARSING - Extract sections from raw text
  // ═══════════════════════════════════════════════════════════════════════
  _ParsedContent _parseInteractionContent(
    DrugInteraction interaction,
    bool isRTL,
  ) {
    String effect = '';
    String mechanism = '';
    String management = '';

    // Get base effect text
    effect =
        (isRTL ? interaction.arabicEffect : interaction.effect) ??
        interaction.effect ??
        '';

    // Get mechanism if available
    mechanism = interaction.mechanismText ?? '';

    // Get management/recommendation
    final recommendation =
        isRTL ? interaction.arabicRecommendation : interaction.recommendation;
    final managementText = interaction.managementText ?? '';

    if (recommendation != null && recommendation.trim().isNotEmpty) {
      management = recommendation;
      // Append management_text only if it's different AND not already contained
      if (managementText.isNotEmpty &&
          managementText.trim() != recommendation.trim() &&
          !recommendation.contains(managementText.trim()) &&
          !managementText.contains(recommendation.trim())) {
        management = '$management\n\n$managementText';
      }
    } else if (managementText.isNotEmpty) {
      management = managementText;
    }

    // For food interactions: try to extract RECOMMENDATION from the effect text
    if (interaction.type == 'food' ||
        interaction.ingredient2.toLowerCase().contains('food')) {
      final extracted = _extractRecommendationFromText(effect);
      if (extracted.recommendation.isNotEmpty) {
        effect = extracted.mainText;
        if (management.isEmpty) {
          management = extracted.recommendation;
        } else if (!management.contains(extracted.recommendation) &&
            !extracted.recommendation.contains(management)) {
          // Only append if they don't overlap
          management = '$management\n\n${extracted.recommendation}';
        }
      }
    }

    // REMOVED FALLBACK:
    // We do NOT show "Consult your physician" text as requested by the user.
    // If management is empty, the section will simply not render.

    return _ParsedContent(
      effect: effect.trim(),
      mechanism: mechanism.trim(),
      management: management.trim(),
    );
  }

  /// Extract "RECOMMENDATION:" section from text
  _ExtractedRecommendation _extractRecommendationFromText(String text) {
    // Common patterns for recommendation sections
    final patterns = [
      RegExp(
        r'RECOMMENDATION[:\s]+(.+?)(?=$|\n\n|\. [A-Z])',
        caseSensitive: false,
        dotAll: true,
      ),
      RegExp(
        r'MANAGEMENT[:\s]+(.+?)(?=$|\n\n|\. [A-Z])',
        caseSensitive: false,
        dotAll: true,
      ),
      RegExp(
        r'ADVICE[:\s]+(.+?)(?=$|\n\n|\. [A-Z])',
        caseSensitive: false,
        dotAll: true,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.group(1) != null) {
        final recommendation = match.group(1)!.trim();
        // Remove the recommendation section from main text
        final mainText = text.replaceFirst(match.group(0)!, '').trim();
        return _ExtractedRecommendation(mainText, recommendation);
      }
    }

    return _ExtractedRecommendation(text, '');
  }

  Color _getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return const Color(0xFFDC2626); // Red-600
      case InteractionSeverity.severe:
        return const Color(0xFFEA580C); // Orange-600
      case InteractionSeverity.major:
        return const Color(0xFFD97706); // Amber-600
      case InteractionSeverity.moderate:
        return const Color(0xFFCA8A04); // Yellow-600
      case InteractionSeverity.minor:
        return const Color(0xFF0891B2); // Cyan-600
      default:
        return const Color(0xFF6B7280); // Gray-500
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
      default:
        return LucideIcons.helpCircle;
    }
  }

  String _getSeverityLabel(InteractionSeverity severity, bool isRTL) {
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
      default:
        return isRTL ? 'غير محدد' : 'N/A';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _ParsedContent {
  final String effect;
  final String mechanism;
  final String management;

  _ParsedContent({
    required this.effect,
    required this.mechanism,
    required this.management,
  });
}

class _ExtractedRecommendation {
  final String mainText;
  final String recommendation;

  _ExtractedRecommendation(this.mainText, this.recommendation);
}

// ═══════════════════════════════════════════════════════════════════════════
// UI COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _InteractionPairCard extends StatelessWidget {
  final ThemeData theme;
  final String agent1;
  final String agent2;
  final bool isFood;
  final bool isRTL;
  final Color severityColor;

  const _InteractionPairCard({
    required this.theme,
    required this.agent1,
    required this.agent2,
    required this.isFood,
    required this.isRTL,
    required this.severityColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row containing both agents opposing each other
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Agent 1 (Left/Start)
              Expanded(
                child: Text(
                  agent1,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),

              // Center Interaction Icon
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.zap, color: severityColor, size: 20),
              ),

              // Agent 2 (Right/End)
              Expanded(
                child: Text(
                  agent2,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: isFood ? Colors.orange.shade700 : null,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData icon;
  final String content;
  final Color accentColor;
  final bool isRTL;
  final bool isHighlighted;

  const _InfoSection({
    required this.theme,
    required this.title,
    required this.icon,
    required this.content,
    required this.accentColor,
    required this.isRTL,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Section Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isHighlighted
                      ? accentColor.withOpacity(0.06)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                        0.4,
                      ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    isHighlighted
                        ? accentColor.withOpacity(0.2)
                        : theme.colorScheme.outline.withOpacity(0.08),
              ),
            ),
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color:
                    isHighlighted
                        ? accentColor.withOpacity(0.9)
                        : theme.colorScheme.onSurface.withOpacity(0.85),
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetadataChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlternativesSection extends StatelessWidget {
  final ThemeData theme;
  final String agent1;
  final List<String>? alternatives1;
  final String agent2;
  final List<String>? alternatives2;
  final bool isRTL;

  const _AlternativesSection({
    required this.theme,
    required this.agent1,
    required this.alternatives1,
    required this.agent2,
    required this.alternatives2,
    required this.isRTL,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.thumbsUp,
                size: 14,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isRTL ? 'البدائل الآمنة المقترحة' : 'Safer Alternatives',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (alternatives1 != null && alternatives1!.isNotEmpty)
          _buildDrugAlternatives(agent1, alternatives1!),

        if (alternatives1 != null &&
            alternatives1!.isNotEmpty &&
            alternatives2 != null &&
            alternatives2!.isNotEmpty)
          const SizedBox(height: 12),

        if (alternatives2 != null && alternatives2!.isNotEmpty)
          _buildDrugAlternatives(agent2, alternatives2!),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDrugAlternatives(String drugName, List<String> alts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRTL ? 'بديل لـ $drugName:' : 'Alternative for $drugName:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                alts
                    .take(5)
                    .map(
                      (alt) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          alt,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(
                              0xFF1B6646,
                            ), // Darker success green
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          if (alts.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                isRTL
                    ? '+ ${alts.length - 5} المزيد'
                    : '+ ${alts.length - 5} more',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
