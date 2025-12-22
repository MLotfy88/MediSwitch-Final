import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/utils/dosage_parser.dart';
import 'package:mediswitch/data/models/dosage_guidelines_model.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

enum PatientType { pediatric, adult }

/// A universal widget for calculating dosages for both Pediatric and Adult patients.
class UniversalDosageCalculator extends StatefulWidget {
  /// Creates a new [UniversalDosageCalculator] instance.
  const UniversalDosageCalculator({
    required this.concentration,
    this.medName,
    this.guidelines,
    super.key,
  });

  /// The concentration string (e.g., "250mg/5ml") to parse.
  final String concentration;

  /// Optional medicine name for display context.
  final String? medName;

  /// Optional list of dosage guidelines to use for suggestions.
  final List<DosageGuidelinesModel>? guidelines;

  @override
  State<UniversalDosageCalculator> createState() =>
      _UniversalDosageCalculatorState();
}

class _UniversalDosageCalculatorState extends State<UniversalDosageCalculator> {
  PatientType _selectedType = PatientType.pediatric;

  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  // For Pediatric: Dose in mg/kg
  // For Adult: Total Dose in mg
  final _dosageController = TextEditingController(text: '10');

  double? _calculatedTotalDoseMg;
  double? _calculatedVolumeMl;
  double? _calculatedUnits; // Tablets/Capsules

  late ({double amount, String unit, double? volume, String? volumeUnit})?
  _parsedConcentration;

  @override
  void initState() {
    super.initState();
    _parsedConcentration = DosageParser.parseConcentration(
      widget.concentration,
    );
    // Default adult dose to something standard if switching
  }

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  void _onTypeChanged(PatientType type) {
    setState(() {
      _selectedType = type;
      if (type == PatientType.adult) {
        // Reset defaults for adult
        _dosageController.text = "500"; // Common adult start
      } else {
        _dosageController.text = "10"; // Common peds mg/kg
      }
      _calculate();
    });
  }

  void _calculate() {
    final doseInput = double.tryParse(_dosageController.text);

    if (_parsedConcentration == null || doseInput == null) {
      setState(() {
        _calculatedTotalDoseMg = null;
        _calculatedVolumeMl = null;
        _calculatedUnits = null;
      });
      return;
    }

    setState(() {
      if (_selectedType == PatientType.pediatric) {
        final weight = double.tryParse(_weightController.text);
        if (weight != null) {
          _calculatedTotalDoseMg = weight * doseInput;
        } else {
          _calculatedTotalDoseMg = null;
        }
      } else {
        // Adult: Input IS the total dose
        _calculatedTotalDoseMg = doseInput;
      }

      if (_calculatedTotalDoseMg != null) {
        if (_parsedConcentration!.volume != null) {
          // Liquid
          _calculatedVolumeMl = DosageParser.calculateVolume(
            targetDoseMg: _calculatedTotalDoseMg!,
            concentrationAmountMg: _parsedConcentration!.amount,
            concentrationVolumeMl: _parsedConcentration!.volume!,
          );
          _calculatedUnits = null;
        } else {
          // Solid
          _calculatedUnits = DosageParser.calculateUnits(
            targetDoseMg: _calculatedTotalDoseMg!,
            concentrationAmountMg: _parsedConcentration!.amount,
          );
          _calculatedVolumeMl = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    if (_parsedConcentration == null) {
      return SizedBox.shrink(); // Use fallback or hidden if invalid
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.border.withValues(alpha: 0.5)),
        boxShadow: appColors.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Segmented Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.calculator,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dose Calculator',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              // Toggle
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleBtn(
                      context,
                      PatientType.pediatric,
                      'Child',
                      LucideIcons.baby,
                    ),
                    _buildToggleBtn(
                      context,
                      PatientType.adult,
                      'Adult',
                      LucideIcons.user,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pediatric Fields
          if (_selectedType == PatientType.pediatric) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg)',
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                      isDense: true,
                    ),
                    onChanged: (_) => _calculate(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age (yr)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Dose Field (Label changes based on type)
          TextField(
            controller: _dosageController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText:
                  _selectedType == PatientType.pediatric
                      ? 'Dose per Weight'
                      : 'Target Total Dose',
              border: const OutlineInputBorder(),
              suffixText:
                  _selectedType == PatientType.pediatric ? 'mg/kg' : 'mg',
              isDense: true,
            ),
            onChanged: (_) => _calculate(),
          ),

          const SizedBox(height: 12),
          Text(
            'Concentration: ${_parsedConcentration!.amount}${_parsedConcentration!.unit}${_parsedConcentration!.volume != null ? ' / ${_parsedConcentration!.volume}${_parsedConcentration!.volumeUnit}' : ''}',
            style: TextStyle(color: appColors.mutedForeground, fontSize: 12),
          ),

          const Divider(height: 24),

          // Results
          if (_calculatedTotalDoseMg != null) ...[
            _buildResultRow(
              theme,
              'Total Dose:',
              '${_calculatedTotalDoseMg!.toStringAsFixed(0)} mg',
            ),
            const SizedBox(height: 8),

            if (_calculatedVolumeMl != null) ...[
              _buildResultRow(
                theme,
                'Volume:',
                '${_calculatedVolumeMl!.toStringAsFixed(1)} ml',
              ),

              if (_selectedType == PatientType.pediatric) ...[
                const SizedBox(height: 12),
                Text(
                  'Divided Doses:',
                  style: TextStyle(
                    fontSize: 12,
                    color: appColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDivisionChip(theme, 2, _calculatedVolumeMl!),
                    _buildDivisionChip(theme, 3, _calculatedVolumeMl!),
                  ],
                ),
              ],
            ] else if (_calculatedUnits != null) ...[
              _buildResultRow(
                theme,
                'Quantity:',
                '${_calculatedUnits!.toStringAsFixed(1)} ${_parsedConcentration!.volume == null ? "Tablets" : "SimUnits"}',
              ),
              // Simple units logic
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildToggleBtn(
    BuildContext context,
    PatientType type,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedType == type;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _onTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color:
                    isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDivisionChip(
    ThemeData theme,
    int divisions,
    double totalVolume,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '${divisions}x Daily',
            style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface),
          ),
          Text(
            '${(totalVolume / divisions).toStringAsFixed(1)} ml',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
