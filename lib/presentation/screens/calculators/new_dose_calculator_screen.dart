import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Modern Dose Calculator Screen
/// Enhanced design matching app style
class NewDoseCalculatorScreen extends StatefulWidget {
  const NewDoseCalculatorScreen({super.key});

  @override
  State<NewDoseCalculatorScreen> createState() =>
      _NewDoseCalculatorScreenState();
}

class _NewDoseCalculatorScreenState extends State<NewDoseCalculatorScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  String _selectedUnit = 'kg';
  String _selectedDoseUnit = 'mg';
  double? _calculatedDose;

  @override
  void dispose() {
    _weightController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  void _calculateDose() {
    final weight = double.tryParse(_weightController.text);
    final dosePerKg = double.tryParse(_doseController.text);

    if (weight != null && dosePerKg != null) {
      setState(() {
        _calculatedDose = weight * dosePerKg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary,
              colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        LucideIcons.arrowLeft,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRTL ? 'حاسبة الجرعة' : 'Dose Calculator',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isRTL
                              ? 'احسب الجرعة بناءً على الوزن'
                              : 'Calculate dose based on weight',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.calculator,
                              size: 40,
                              color: colorScheme.primary,
                            ),
                          ),
                        ).animate().scale(
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),

                        const SizedBox(height: 32),

                        // Weight Input
                        _buildInputCard(
                              context,
                              label: isRTL ? 'الوزن' : 'Weight',
                              controller: _weightController,
                              hint: isRTL ? 'أدخل الوزن' : 'Enter weight',
                              icon: LucideIcons.scale,
                              unit: _selectedUnit,
                              onUnitChanged: (value) {
                                setState(() => _selectedUnit = value!);
                              },
                              units: ['kg', 'lbs'],
                            )
                            .animate(delay: 100.ms)
                            .fadeIn()
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 16),

                        // Dose per kg Input
                        _buildInputCard(
                              context,
                              label: isRTL ? 'الجرعة لكل كجم' : 'Dose per kg',
                              controller: _doseController,
                              hint: isRTL ? 'أدخل الجرعة' : 'Enter dose',
                              icon: LucideIcons.droplets,
                              unit: _selectedDoseUnit,
                              onUnitChanged: (value) {
                                setState(() => _selectedDoseUnit = value!);
                              },
                              units: ['mg', 'mcg', 'ml'],
                            )
                            .animate(delay: 200.ms)
                            .fadeIn()
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),

                        // Calculate Button
                        ElevatedButton(
                              onPressed: _calculateDose,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.calculator, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    isRTL ? 'احسب' : 'Calculate',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate(delay: 300.ms)
                            .fadeIn()
                            .slideY(begin: 0.1, end: 0),

                        // Result
                        if (_calculatedDose != null) ...[
                          const SizedBox(height: 24),
                          Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      isRTL
                                          ? 'الجرعة المحسوبة'
                                          : 'Calculated Dose',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_calculatedDose!.toStringAsFixed(2)} $_selectedDoseUnit',
                                      style: theme.textTheme.displaySmall
                                          ?.copyWith(
                                            color: colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String unit,
    required ValueChanged<String?> onUnitChanged,
    required List<String> units,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: unit,
                items:
                    units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                onChanged: onUnitChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
