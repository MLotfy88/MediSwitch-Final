import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/utils/dosage_parser.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/widgets/details/universal_dosage_calculator.dart';

class StandAlonePediatricCalculatorScreen extends StatefulWidget {
  /// Creates a new [StandAlonePediatricCalculatorScreen] instance.
  const StandAlonePediatricCalculatorScreen({super.key});

  @override
  State<StandAlonePediatricCalculatorScreen> createState() =>
      _StandAlonePediatricCalculatorScreenState();
}

class _StandAlonePediatricCalculatorScreenState
    extends State<StandAlonePediatricCalculatorScreen> {
  final _concentrationController = TextEditingController();
  String? _parsedConcentrationDisplay;
  bool _isValidConcentration = false;

  @override
  void dispose() {
    _concentrationController.dispose();
    super.dispose();
  }

  void _validateConcentration(String value) {
    setState(() {
      final result = DosageParser.parseConcentration(value);
      if (result != null) {
        _isValidConcentration = true;
        _parsedConcentrationDisplay =
            '✅ Valid: $value (${result.amount}${result.unit} / ${result.volume ?? 1}${result.volumeUnit ?? "ml"})';
      } else {
        _isValidConcentration = false;
        _parsedConcentrationDisplay = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final appColors = theme.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Dose Calculator'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Manual Concentration Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: appColors.border.withValues(alpha: 0.5),
                ),
                boxShadow: appColors.shadowCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1: Enter Medicine Concentration',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Examples: 250mg/5ml, 125mg/5ml, 100mg/1ml',
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _concentrationController,
                    decoration: InputDecoration(
                      labelText: 'Concentration (e.g. 250mg/5ml)',
                      border: const OutlineInputBorder(),
                      suffixIcon: Icon(
                        _isValidConcentration
                            ? Icons.check_circle
                            : LucideIcons.flaskConical,
                        color:
                            _isValidConcentration
                                ? appColors.success
                                : appColors.mutedForeground,
                      ),
                    ),
                    onChanged: _validateConcentration,
                  ),
                  if (_parsedConcentrationDisplay != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _parsedConcentrationDisplay!,
                        style: TextStyle(
                          color: appColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Calculator Widget (Only show if valid)
            if (_isValidConcentration) ...[
              Text(
                'Step 2: Calculate Dose',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              UniversalDosageCalculator(
                concentration: _concentrationController.text,
              ),
            ] else if (_concentrationController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: appColors.warningSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 16,
                      color: appColors.warningForeground,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please enter a valid concentration format (e.g. 250mg/5ml)',
                        style: TextStyle(color: appColors.warningForeground),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
