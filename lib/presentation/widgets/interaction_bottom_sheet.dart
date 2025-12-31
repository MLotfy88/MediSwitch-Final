import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';

class InteractionBottomSheet extends StatelessWidget {
  const InteractionBottomSheet({super.key, required this.interaction});

  final DrugInteraction interaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final isFood =
        interaction.type == 'food' ||
        interaction.ingredient2.toLowerCase().contains('food') ||
        interaction.ingredient2.toLowerCase().contains('diet');

    final severityColor = _getSeverityColor(interaction.severityEnum, theme);
    final severityIcon = _getSeverityIcon(interaction.severityEnum);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 2. Header with Severity Badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFood
                            ? (isRTL ? 'تفاعل غذائي' : 'Food Interaction')
                            : (isRTL ? 'تفاعل دوائي' : 'Drug Interaction'),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRTL
                            ? 'تحليل المخاطر السريرية والملف الشخصي'
                            : 'Clinical Risk Analysis & Profile',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          fontSize: 12.5, // Further reduced as requested
                          color: severityColor.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: severityColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(severityIcon, color: severityColor, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        _getSeverityLabel(interaction.severityEnum, isRTL),
                        style: TextStyle(
                          color: severityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Divider(),
          ),

          // 3. Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interaction Pair
                  _AgentBox(
                    theme: theme,
                    isRTL: isRTL,
                    agent1: interaction.ingredient1,
                    agent2: interaction.ingredient2,
                    isFood: isFood,
                  ),

                  const SizedBox(height: 24),

                  // CLINICAL EFFECT
                  _SectionHeader(
                    title: isRTL ? 'التأثير السريري' : 'Clinical Effect',
                    icon: LucideIcons.stethoscope,
                    theme: theme,
                  ),
                  _ContentBox(
                    content:
                        (isRTL
                            ? interaction.arabicEffect
                            : interaction.effect) ??
                        interaction.effect ??
                        (isRTL ? 'لا تفاصيل' : 'No details'),
                    theme: theme,
                  ),

                  const SizedBox(height: 20),

                  // MECHANISM (NEW)
                  if (interaction.mechanismText != null &&
                      interaction.mechanismText!.isNotEmpty) ...[
                    _SectionHeader(
                      title: isRTL ? 'آلية التفاعل' : 'Mechanism of Action',
                      icon: LucideIcons.layers,
                      theme: theme,
                    ),
                    _ContentBox(
                      content: interaction.mechanismText!,
                      theme: theme,
                      isDimmed: true,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // RECOMMENDATION / MANAGEMENT (ENRICHED)
                  if (!isFood) ...[
                    _SectionHeader(
                      title: isRTL ? 'التوصية الطبية' : 'Clinical Management',
                      icon: LucideIcons.shieldCheck,
                      theme: theme,
                      color: AppColors.success,
                    ),
                    _ContentBox(
                      content: _buildManagementValue(interaction, isRTL),
                      theme: theme,
                      color: AppColors.success.withValues(alpha: 0.05),
                      borderColor: AppColors.success.withValues(alpha: 0.2),
                      textColor: AppColors.success,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // RISK LEVEL & ID (NEW)
                  Row(
                    children: [
                      if (interaction.riskLevel != null)
                        Expanded(
                          child: _DetailChip(
                            label: isRTL ? 'مستوى الخطر' : 'Risk Level',
                            value: interaction.riskLevel!,
                            icon: LucideIcons.alertOctagon,
                            color: severityColor,
                            theme: theme,
                          ),
                        ),
                      if (interaction.riskLevel != null &&
                          interaction.ddinterId != null)
                        const SizedBox(width: 12),
                      if (interaction.ddinterId != null)
                        Expanded(
                          child: _DetailChip(
                            label: isRTL ? 'معرف المرجع' : 'Reference ID',
                            value: interaction.ddinterId!,
                            icon: LucideIcons.hash,
                            color: theme.colorScheme.secondary,
                            theme: theme,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // 4. Action
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isRTL ? 'إغلاق التفاصيل' : 'Dismiss Analysis',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildManagementValue(DrugInteraction interaction, bool isRTL) {
    final List<String> parts = [];
    final mainRec =
        isRTL ? interaction.arabicRecommendation : interaction.recommendation;
    if (mainRec != null && mainRec.isNotEmpty) parts.add(mainRec);

    if (interaction.managementText != null &&
        interaction.managementText!.isNotEmpty) {
      parts.add(interaction.managementText!);
    }

    return parts.isEmpty
        ? (isRTL
            ? 'تم الإبلاغ عن تفاعل؛ استشر الصيدلي.'
            : 'Interaction reported; consult pharmacist.')
        : parts.join('\n\n');
  }

  Color _getSeverityColor(InteractionSeverity severity, ThemeData theme) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return AppColors.danger;
      case InteractionSeverity.severe:
        return AppColors.danger;
      case InteractionSeverity.major:
        return Colors.orange[800]!;
      case InteractionSeverity.moderate:
        return AppColors.warning;
      case InteractionSeverity.minor:
        return AppColors.info;
      default:
        return Colors.grey;
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
      default:
        return LucideIcons.info;
    }
  }

  String _getSeverityLabel(InteractionSeverity severity, bool isRTL) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return isRTL ? 'ممنوع' : 'CI';
      case InteractionSeverity.severe:
        return isRTL ? 'شديد خطورة' : 'Severe';
      case InteractionSeverity.major:
        return isRTL ? 'هام جداً' : 'Major';
      case InteractionSeverity.moderate:
        return isRTL ? 'متوسط' : 'Moderate';
      case InteractionSeverity.minor:
        return isRTL ? 'طفيـف' : 'Minor';
      default:
        return isRTL ? 'غير محدد' : 'N/A';
    }
  }
}

class _AgentBox extends StatelessWidget {
  final ThemeData theme;
  final bool isRTL;
  final String agent1;
  final String agent2;
  final bool isFood;

  const _AgentBox({
    required this.theme,
    required this.isRTL,
    required this.agent1,
    required this.agent2,
    required this.isFood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.15,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          _AgentRow(
            name: agent1,
            icon: LucideIcons.pill,
            color: theme.colorScheme.primary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Icon(LucideIcons.plus, size: 16, color: Colors.grey),
          ),
          _AgentRow(
            name: agent2,
            icon: isFood ? LucideIcons.apple : LucideIcons.pill,
            color: isFood ? Colors.orange : theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _AgentRow extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const _AgentRow({
    required this.name,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeData theme;
  final Color? color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.theme,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: activeColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentBox extends StatelessWidget {
  final String content;
  final ThemeData theme;
  final Color? color;
  final Color? borderColor;
  final Color? textColor;
  final bool isDimmed;

  const _ContentBox({
    required this.content,
    required this.theme,
    this.color,
    this.borderColor,
    this.textColor,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            color ??
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              borderColor ?? theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        content,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color:
              textColor ??
              (isDimmed
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                  : theme.colorScheme.onSurface),
          fontSize: 14,
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  const _DetailChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
