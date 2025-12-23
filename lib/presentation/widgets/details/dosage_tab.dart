import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/app_spacing.dart';
import 'package:mediswitch/data/models/dosage_guidelines_model.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/widgets/details/universal_dosage_calculator.dart';
import 'package:provider/provider.dart';

/// Tab displaying dosage information for a specific [drug].
class DosageTab extends StatelessWidget {
  /// Creates a new [DosageTab] instance.
  const DosageTab({required this.drug, super.key});

  /// The drug entity for which to display dosage information.
  final DrugEntity drug;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: AppSpacing.edgeInsetsAllLarge,
      child: FutureBuilder<List<DosageGuidelinesModel>>(
        future: Provider.of<MedicineProvider>(
          context,
          listen: false,
        ).getDosageGuidelines(drug.id ?? 0),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final guidelines = snapshot.data ?? [];
          DosageGuidelinesModel? summaryGuideline;

          if (guidelines.isNotEmpty) {
            summaryGuideline = guidelines.first;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick Stats Grid
              _buildQuickStats(context, l10n, summaryGuideline),
              const SizedBox(height: 24),

              // Pediatric Calculator (Collapsible or always visible if pediatric)
              if (drug.concentration.isNotEmpty) ...[
                UniversalDosageCalculator(
                  concentration: drug.concentration,
                  medName: drug.tradeName,
                  guidelines: guidelines,
                ),
                const SizedBox(height: 24),
              ],

              // Standard Matrix Title
              if (guidelines.isNotEmpty) ...[
                Text(
                  l10n.standardDosePerIndication,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildIndicationMatrix(context, l10n, guidelines),
                const SizedBox(height: 24),
              ],

              // Original Warning for fallback instructions
              if (summaryGuideline?.instructions != null)
                InstructionsWarning(
                  instructions:
                      summaryGuideline?.instructions ??
                      l10n.consultDoctorOrPharmacist,
                ),
            ],
          ).animate().fadeIn();
        },
      ),
    );
  }

  Widget _buildQuickStats(
    BuildContext context,
    AppLocalizations l10n,
    DosageGuidelinesModel? guideline,
  ) {
    final theme = Theme.of(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          l10n.regularFrequency,
          guideline?.frequency != null
              ? (guideline!.frequency == 24
                  ? (l10n.localeName == 'ar' ? 'مرة يومياً' : 'Once daily')
                  : l10n.timesDaily(guideline!.frequency!))
              : (l10n.localeName == 'ar' ? 'حسب الإرشاد' : 'As directed'),
          LucideIcons.clock,
          theme.colorScheme.primary,
        ),
        _buildStatCard(
          context,
          l10n.maxDailyDose,
          guideline?.maxDose != null && guideline!.maxDose! > 0
              ? '${guideline!.maxDose} mg'
              : (l10n.localeName == 'ar' ? 'راجع النشرة' : 'See leaflet'),
          LucideIcons.alertCircle,
          theme.colorScheme.error,
        ),
        _buildStatCard(
          context,
          l10n.administrationForm,
          drug.dosageForm,
          LucideIcons.pill,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          l10n.treatmentDuration,
          guideline?.duration != null && guideline!.duration! > 0
              ? '${guideline!.duration} ${l10n.localeName == 'ar' ? 'أيام' : 'days'}'
              : (l10n.localeName == 'ar' ? 'حسب الإرشاد' : 'As directed'),
          LucideIcons.calendar,
          theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: appColors.shadowCard,
        border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: appColors.mutedForeground),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicationMatrix(
    BuildContext context,
    AppLocalizations l10n,
    List<DosageGuidelinesModel> guidelines,
  ) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: appColors.shadowCard,
        border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    l10n.conditionLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    l10n.standardDose,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ...guidelines.asMap().entries.map((entry) {
            final index = entry.key;
            final g = entry.value;
            final isLast = index == guidelines.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border:
                    isLast
                        ? null
                        : Border(
                          bottom: BorderSide(
                            color: appColors.border.withValues(alpha: 0.5),
                          ),
                        ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.condition ?? 'General',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (g.isPediatric)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Pediatric',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${g.minDose ?? "-"} mg',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// A warning widget that displays dosage instructions.
class InstructionsWarning extends StatelessWidget {
  /// Creates a new [InstructionsWarning] instance.
  const InstructionsWarning({required this.instructions, super.key});

  /// The instructions to display.
  final String instructions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.warningSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.warningSoft.withValues()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                size: 16,
                color: appColors.warningForeground,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions', // Localize later
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: appColors.warningForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            instructions,
            style: TextStyle(
              color: appColors.warningForeground.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
