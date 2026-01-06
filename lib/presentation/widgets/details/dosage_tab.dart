import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/app_spacing.dart';
import 'package:mediswitch/core/utils/dosage_parser.dart';
import 'package:mediswitch/data/models/dosage_guidelines_model.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:provider/provider.dart';

/// تبويبة الجرعات المصغرة
class DosageTab extends StatelessWidget {
  /// Creates a dosage tab
  const DosageTab({required this.drug, super.key});

  /// The drug entity
  final DrugEntity drug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = l10n.localeName == 'ar';

    return SingleChildScrollView(
      padding: AppSpacing.edgeInsetsAllMedium,
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
          final primary = guidelines.isNotEmpty ? guidelines.first : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StandardDoseCard(
                guideline: primary,
                drugForm: drug.dosageForm,
                isAr: isAr,
              ),
              const SizedBox(height: 16),
              if (drug.concentration.isNotEmpty)
                _MiniDoseCalculator(
                  concentration: drug.concentration,
                  standardDose: primary?.minDose,
                  isAr: isAr,
                ),
              if (primary?.instructions != null &&
                  primary!.instructions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InstructionsCard(
                  instructions: primary.instructions!,
                  source: primary.source ?? 'WHO',
                  isAr: isAr,
                ),
              ],
            ],
          ).animate().fadeIn(duration: 300.ms);
        },
      ),
    );
  }
}

class _StandardDoseCard extends StatelessWidget {
  const _StandardDoseCard({
    required this.guideline,
    required this.drugForm,
    required this.isAr,
  });

  final DosageGuidelinesModel? guideline;
  final String drugForm;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final dose = guideline?.minDose;
    final maxDose = guideline?.maxDose;
    final freq = guideline?.frequency;
    final route = guideline?.route ?? drugForm;
    final duration = guideline?.duration;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.pill,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isAr ? 'الجرعة القياسية' : 'Standard Dose',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: LucideIcons.activity,
                  label: isAr ? 'الجرعة' : 'Dose',
                  value:
                      dose != null
                          ? (maxDose != null && maxDose > dose
                              ? '$dose - $maxDose mg'
                              : '$dose mg')
                          : (isAr ? 'راجع النشرة' : 'See leaflet'),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: LucideIcons.clock,
                  label: isAr ? 'التكرار' : 'Frequency',
                  value: _formatFrequency(freq, isAr),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: LucideIcons.navigation,
                  label: isAr ? 'الطريق' : 'Route',
                  value: route.isNotEmpty ? route : '-',
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: LucideIcons.calendar,
                  label: isAr ? 'المدة' : 'Duration',
                  value:
                      duration != null && duration > 0
                          ? '$duration ${isAr ? 'يوم' : 'days'}'
                          : (isAr ? 'حسب الحالة' : 'As needed'),
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFrequency(int? freq, bool isAr) {
    if (freq == null || freq <= 0) {
      return isAr ? 'حسب الإرشاد' : 'As directed';
    }
    if (freq == 24) return isAr ? 'مرة يومياً' : 'Once daily';
    if (freq == 12) return isAr ? 'مرتين يومياً' : 'Twice daily';
    if (freq == 8) return isAr ? '3 مرات يومياً' : '3 times daily';
    if (freq == 6) return isAr ? '4 مرات يومياً' : '4 times daily';
    return isAr ? 'كل $freq ساعة' : 'Every $freq hours';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 11, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDoseCalculator extends StatefulWidget {
  const _MiniDoseCalculator({
    required this.concentration,
    required this.isAr,
    this.standardDose,
  });

  final String concentration;
  final double? standardDose;
  final bool isAr;

  @override
  State<_MiniDoseCalculator> createState() => _MiniDoseCalculatorState();
}

class _MiniDoseCalculatorState extends State<_MiniDoseCalculator> {
  final _weightController = TextEditingController();
  final _dosePerKgController = TextEditingController(text: '10');
  double? _resultMg;
  double? _resultMl;

  @override
  void initState() {
    super.initState();
    if (widget.standardDose != null) {
      _dosePerKgController.text = widget.standardDose!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _dosePerKgController.dispose();
    super.dispose();
  }

  void _calculate() {
    final weight = double.tryParse(_weightController.text);
    final dosePerKg = double.tryParse(_dosePerKgController.text);

    if (weight == null || dosePerKg == null) {
      setState(() {
        _resultMg = null;
        _resultMl = null;
      });
      return;
    }

    final totalMg = weight * dosePerKg;
    final parsed = DosageParser.parseConcentration(widget.concentration);

    setState(() {
      _resultMg = totalMg;
      if (parsed != null && parsed.volume != null && parsed.amount > 0) {
        _resultMl = (totalMg / parsed.amount) * parsed.volume!;
      } else {
        _resultMl = null;
      }
    });
  }

  void _copyResult() {
    if (_resultMg == null) return;
    final text =
        _resultMl != null
            ? '${_resultMg!.toStringAsFixed(1)} mg '
                '(${_resultMl!.toStringAsFixed(1)} ml)'
            : '${_resultMg!.toStringAsFixed(1)} mg';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isAr ? 'تم النسخ' : 'Copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.border.withValues(alpha: 0.3)),
        boxShadow: appColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.calculator,
                size: 18,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isAr ? 'حاسبة الجرعة' : 'Dose Calculator',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InputField(
                  controller: _weightController,
                  label: widget.isAr ? 'الوزن (kg)' : 'Weight (kg)',
                  hint: '25',
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputField(
                  controller: _dosePerKgController,
                  label: widget.isAr ? 'mg/kg' : 'mg/kg',
                  hint: '10',
                  onChanged: (_) => _calculate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_resultMg != null)
            GestureDetector(
              onTap: _copyResult,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isAr ? 'الجرعة المحسوبة:' : 'Calculated:',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _resultMl != null
                              ? '${_resultMg!.toStringAsFixed(1)} mg '
                                  '(${_resultMl!.toStringAsFixed(1)} ml)'
                              : '${_resultMg!.toStringAsFixed(1)} mg',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      LucideIcons.copy,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({
    required this.instructions,
    required this.source,
    required this.isAr,
  });

  final String instructions;
  final String source;
  final bool isAr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.infoSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, size: 16, color: appColors.info),
              const SizedBox(width: 8),
              Text(
                isAr ? 'إرشادات WHO' : 'WHO Guidelines',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: appColors.info,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                source,
                style: TextStyle(
                  fontSize: 10,
                  color: appColors.info.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            instructions,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
