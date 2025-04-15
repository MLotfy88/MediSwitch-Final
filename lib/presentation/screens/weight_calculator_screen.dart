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
    // Read only once for the list
    // TODO: Filter this list for drugs compatible with dose calculation
    final allDrugs = context.read<MedicineProvider>().filteredMedicines;

    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة الجرعات بالوزن')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Use CustomSearchableDropdown
              CustomSearchableDropdown(
                items: allDrugs,
                selectedItem:
                    calculatorProvider.selectedDrug, // Get value from provider
                onChanged: (DrugEntity? newValue) {
                  // Update provider state directly
                  context.read<DoseCalculatorProvider>().setSelectedDrug(
                    newValue,
                  );
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
              const SizedBox(height: 16),

              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'وزن المريض (كجم)',
                  prefixIcon: Icon(
                    LucideIcons.scale,
                    color: colorScheme.primary,
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال الوزن';
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0)
                    return 'وزن غير صالح';
                  return null;
                },
                onChanged:
                    (value) =>
                        context.read<DoseCalculatorProvider>().setWeight(value),
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'عمر المريض (سنوات)',
                  prefixIcon: Icon(
                    LucideIcons.calendarDays,
                    color: colorScheme.primary,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'يرجى إدخال العمر';
                  if (int.tryParse(value) == null || int.parse(value) < 0)
                    return 'عمر غير صالح';
                  return null;
                },
                onChanged:
                    (value) =>
                        context.read<DoseCalculatorProvider>().setAge(value),
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                icon:
                    calculatorProvider.isLoading
                        ? Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(left: 8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                        : Icon(LucideIcons.calculator, size: 20),
                label: Text(
                  calculatorProvider.isLoading
                      ? 'جاري الحساب...'
                      : 'حساب الجرعة',
                ),
                onPressed: calculatorProvider.isLoading ? null : _calculateDose,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- Results Area ---
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    if (calculatorProvider.error.isNotEmpty)
                      _buildResultCard(
                        context,
                        title: 'خطأ',
                        content: calculatorProvider.error,
                        icon: LucideIcons.alertTriangle,
                        color: colorScheme.errorContainer,
                        iconColor: colorScheme.onErrorContainer,
                      )
                    else if (calculatorProvider.dosageResult != null)
                      Column(
                        children: [
                          _buildResultCard(
                            context,
                            title: 'الجرعة المحسوبة',
                            content: calculatorProvider.dosageResult!.dosage,
                            icon: LucideIcons.checkCircle2,
                            color: Colors.green.shade50,
                            iconColor: Colors.green.shade800,
                          ),
                          if (calculatorProvider.dosageResult!.notes != null &&
                              calculatorProvider
                                  .dosageResult!
                                  .notes!
                                  .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildResultCard(
                              context,
                              title: 'ملاحظات',
                              content: calculatorProvider.dosageResult!.notes!,
                              icon: LucideIcons.info,
                              color: colorScheme.secondaryContainer.withOpacity(
                                0.5,
                              ),
                              iconColor: colorScheme.onSecondaryContainer,
                            ),
                          ],
                          if (calculatorProvider.dosageResult!.warning !=
                                  null &&
                              calculatorProvider
                                  .dosageResult!
                                  .warning!
                                  .isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildResultCard(
                              context,
                              title: 'تحذير',
                              content:
                                  calculatorProvider.dosageResult!.warning!,
                              icon: LucideIcons.alertTriangle,
                              color: Colors.orange.shade100,
                              iconColor: Colors.orange.shade800,
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Save Calculation Button (Premium)
              OutlinedButton.icon(
                icon: Icon(
                  LucideIcons.save,
                  size: 18,
                  color: colorScheme.primary.withOpacity(0.6),
                ),
                label: Text(
                  'حفظ الحساب (Premium)',
                  style: TextStyle(color: colorScheme.primary.withOpacity(0.6)),
                ),
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
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
