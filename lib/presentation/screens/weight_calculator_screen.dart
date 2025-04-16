import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/dose_calculator_provider.dart';
import '../bloc/medicine_provider.dart';
import '../../domain/entities/drug_entity.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../widgets/custom_searchable_dropdown.dart'; // Import the searchable dropdown

class WeightCalculatorScreen extends StatefulWidget {
  const WeightCalculatorScreen({super.key});

  @override
  State<WeightCalculatorScreen> createState() => _WeightCalculatorScreenState();
}

class _WeightCalculatorScreenState extends State<WeightCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final FileLoggerService _logger = locator<FileLoggerService>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  // Selected drug is now managed by the provider, no need for local state here

  @override
  void initState() {
    super.initState();
    // Initialize controllers with provider values if they exist
    final provider = context.read<DoseCalculatorProvider>();
    _weightController.text = provider.weightInput;
    _ageController.text = provider.ageInput;
    // _selectedDrug is now directly from provider.selectedDrug
  }

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _calculateDose() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      final provider = context.read<DoseCalculatorProvider>();
      // Validator ensures selectedDrug is not null here
      provider.setWeight(_weightController.text);
      provider.setAge(_ageController.text);
      _logger.i("WeightCalculatorScreen: Calculating dose...");
      provider.calculateDose();
    } else {
      _logger.w("WeightCalculatorScreen: Form validation failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d("WeightCalculatorScreen: Building widget.");
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final calculatorProvider = context.watch<DoseCalculatorProvider>();
    // Use the currently filtered list from MedicineProvider for the dropdown.
    // Note: This might not contain ALL drugs if filters are active elsewhere.
    final availableDrugs = context.watch<MedicineProvider>().filteredMedicines;

    return Scaffold(
      appBar: AppBar(
        // Apply design styles
        backgroundColor: colorScheme.primary, // #16BC88
        foregroundColor: colorScheme.onPrimary, // White text/icons
        elevation: 0, // Or keep default elevation if preferred
        title: Text(
          'حاسبة الجرعة بالوزن',
          style: textTheme.titleLarge?.copyWith(
            // text-xl equivalent
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // Keep overall padding
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Input Card ---
              Card(
                elevation: 1, // Subtle elevation
                margin: EdgeInsets.zero, // Use outer padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0), // rounded-lg
                ),
                color: colorScheme.surface, // bg-card (adjust if theme differs)
                child: Padding(
                  padding: const EdgeInsets.all(24.0), // p-6
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Use CustomSearchableDropdown
                      CustomSearchableDropdown(
                        items: availableDrugs, // Use the available list
                        selectedItem:
                            calculatorProvider
                                .selectedDrug, // Get value from provider
                        onChanged: (DrugEntity? newValue) {
                          // Update provider state directly
                          context
                              .read<DoseCalculatorProvider>()
                              .setSelectedDrug(newValue);
                        },
                        labelText: 'اختر الدواء',
                        hintText: 'ابحث عن اسم الدواء...',
                        prefixIcon: LucideIcons.pill,
                        validator:
                            (_) =>
                                calculatorProvider.selectedDrug == null
                                    ? 'يرجى اختيار الدواء'
                                    : null,
                      ),
                      const SizedBox(height: 16), // space-y-4

                      TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: 'وزن المريض (كجم)',
                          prefixIcon: Icon(
                            LucideIcons
                                .scale, // Use scale icon as 'weight' doesn't exist
                            size: 18, // Match design size (approx h-4 w-4)
                            color: colorScheme.primary,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'يرجى إدخال الوزن';
                          if (double.tryParse(value) == null ||
                              double.parse(value) <= 0)
                            return 'وزن غير صالح';
                          return null;
                        },
                        onChanged:
                            (value) => context
                                .read<DoseCalculatorProvider>()
                                .setWeight(value),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16), // space-y-4

                      TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: 'عمر المريض (سنوات)',
                          prefixIcon: Icon(
                            LucideIcons.calendar, // Correct icon
                            size: 18, // Match design size (approx h-4 w-4)
                            color: colorScheme.primary,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'يرجى إدخال العمر';
                          if (int.tryParse(value) == null ||
                              int.parse(value) < 0)
                            return 'عمر غير صالح';
                          return null;
                        },
                        onChanged:
                            (value) => context
                                .read<DoseCalculatorProvider>()
                                .setAge(value),
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(
                        height: 24,
                      ), // space-y-4 (adjust final spacing)

                      SizedBox(
                        // Ensure button takes full width
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon:
                              calculatorProvider.isLoading
                                  ? Container(
                                    width: 16, // Match icon size
                                    height: 16,
                                    margin: const EdgeInsets.only(left: 8),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                  : Icon(
                                    LucideIcons.calculator,
                                    size: 16,
                                  ), // h-4 w-4
                          label: Text(
                            calculatorProvider.isLoading
                                ? 'جاري الحساب...'
                                : 'حساب الجرعة',
                          ),
                          onPressed:
                              calculatorProvider.isLoading
                                  ? null
                                  : _calculateDose,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ), // Adjust padding if needed
                            textStyle: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor:
                                colorScheme.primary, // variant="primary"
                            foregroundColor: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24), // mb-6 equivalent
              // --- Results Area ---
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    if (calculatorProvider.error.isNotEmpty)
                      // Keep using _buildResultCard for errors
                      _buildResultCard(
                        context,
                        title: 'خطأ',
                        content: calculatorProvider.error,
                        icon: LucideIcons.alertTriangle,
                        color: colorScheme.errorContainer,
                        iconColor: colorScheme.onErrorContainer,
                      )
                    else if (calculatorProvider.dosageResult != null)
                      // --- New Result Card ---
                      Card(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            8.0,
                          ), // rounded-lg
                        ),
                        color: colorScheme.surface, // bg-card
                        child: Padding(
                          padding: const EdgeInsets.all(24.0), // p-6
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Text(
                                'الجرعة المحسوبة',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ), // text-lg font-bold
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              // Dosage Value
                              Text(
                                calculatorProvider.dosageResult!.dosage,
                                style: textTheme.headlineMedium?.copyWith(
                                  // text-2xl equivalent
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary, // text-primary
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

                              // Optional Warning Section
                              if (calculatorProvider.dosageResult!.warning !=
                                      null &&
                                  calculatorProvider
                                      .dosageResult!
                                      .warning!
                                      .isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 8,
                                  ), // Add some margin
                                  padding: const EdgeInsets.all(12.0), // p-3
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100.withOpacity(
                                      0.7,
                                    ), // bg-warning/10 (adjust opacity)
                                    borderRadius: BorderRadius.circular(
                                      6.0,
                                    ), // rounded-md
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons
                                            .alertTriangle, // Use AlertTriangle for warning
                                        size: 18, // h-4 w-4
                                        color:
                                            Colors
                                                .orange
                                                .shade800, // text-warning
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          calculatorProvider
                                              .dosageResult!
                                              .warning!,
                                          style: textTheme.bodyMedium?.copyWith(
                                            // text-sm
                                            color:
                                                Colors
                                                    .orange
                                                    .shade900, // text-warning
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Optional Notes Section (Can use _buildResultCard style if needed)
                              if (calculatorProvider.dosageResult!.notes !=
                                      null &&
                                  calculatorProvider
                                      .dosageResult!
                                      .notes!
                                      .isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8.0,
                                    bottom: 8.0,
                                  ),
                                  child: _buildResultCard(
                                    // Reuse helper for notes styling
                                    context,
                                    title: 'ملاحظات',
                                    content:
                                        calculatorProvider.dosageResult!.notes!,
                                    icon: LucideIcons.info,
                                    color: colorScheme.secondaryContainer
                                        .withOpacity(0.3),
                                    iconColor: colorScheme.onSecondaryContainer,
                                  ),
                                ),

                              // Save Button (Inside Card)
                              const SizedBox(height: 16), // mt-4 equivalent
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: Icon(
                                    LucideIcons.bookmark, // Correct icon
                                    size: 16, // h-4 w-4
                                  ),
                                  label: const Text('حفظ النتيجة (Premium)'),
                                  onPressed: () {
                                    // Show premium toast/snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              LucideIcons.lock,
                                              size: 16,
                                              color:
                                                  colorScheme.onInverseSurface,
                                            ),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Text(
                                                'هذه الميزة تتطلب الاشتراك Premium.',
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor:
                                            colorScheme.inverseSurface,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    foregroundColor:
                                        colorScheme.primary, // Match design
                                    side: BorderSide(
                                      color: colorScheme.outline,
                                    ), // variant="outline"
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24), // Keep overall bottom spacing
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: iconColor.withOpacity(0.9),
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
