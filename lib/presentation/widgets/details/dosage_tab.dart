import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/app_spacing.dart';
import 'package:mediswitch/data/models/dosage_guidelines_model.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:provider/provider.dart';

class DosageTab extends StatelessWidget {
  final DrugEntity drug;

  const DosageTab({required this.drug, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          DosageGuidelinesModel? bestMatch;

          // Logic to find best match (currently just first)
          if (guidelines.isNotEmpty) {
            bestMatch = guidelines.first;
          }

          return Column(
            children: [
              StrengthCard(drug: drug),
              const SizedBox(height: 16),
              DosageDetailsCard(drug: drug, guideline: bestMatch),
              const SizedBox(height: 16),
              if (bestMatch?.instructions != null || bestMatch?.maxDose != null)
                InstructionsWarning(
                  instructions:
                      bestMatch?.instructions ??
                      'Always read the leaflet and consult your healthcare provider for specific instructions.',
                ),
            ],
          ).animate().fadeIn();
        },
      ),
    );
  }
}

class StrengthCard extends StatelessWidget {
  final DrugEntity drug;

  const StrengthCard({required this.drug, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.appColors;

    String strengthDisplay =
        drug.concentration.isNotEmpty
            ? drug.concentration
            : 'Standard Strength';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: appColors.shadowCard,
        border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.droplets,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strength', // localize later
                  style: TextStyle(
                    color: appColors.mutedForeground,
                    fontSize: 12,
                  ),
                ),
                Text(
                  strengthDisplay,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DosageDetailsCard extends StatelessWidget {
  final DrugEntity drug;
  final DosageGuidelinesModel? guideline;

  const DosageDetailsCard({required this.drug, this.guideline, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appColors = theme.appColors;

    // Construct Display Values
    String standardDose;
    if (guideline != null && guideline!.minDose != null) {
      // FIX: Do not show range (min-max) if max is likely daily limit.
      // If min and max are close (e.g. 5-10), it's a range.
      // If max is much larger (e.g. > 2x min), it's likely daily max.
      // For safety and clarity, let's just show minDose as "Standard/Single Dose"
      // and let Max Daily be separate.
      final freqPart =
          guideline!.frequency != null ? ' (${guideline!.frequency}x/day)' : '';
      standardDose = '${guideline!.minDose} mg$freqPart';
    } else {
      standardDose = drug.usage.isNotEmpty ? drug.usage : 'Consult your doctor';
    }

    final maxDose = guideline?.maxDose?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: appColors.shadowCard,
        border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Standard Dose
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.clock,
                  size: 20,
                  color: appColors.mutedForeground,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Standard Dose', // Localize
                      style: TextStyle(
                        color: appColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      standardDose,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (maxDose != null && maxDose.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            // Maximum Daily Dose
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    LucideIcons.info,
                    size: 20,
                    color: appColors.mutedForeground,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maximum Daily Dose', // Localize
                        style: TextStyle(
                          color: appColors.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$maxDose mg',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class InstructionsWarning extends StatelessWidget {
  final String instructions;

  const InstructionsWarning({required this.instructions, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.warningSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.warningSoft.withValues(), width: 1),
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
                'Instructions', // Localize
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
