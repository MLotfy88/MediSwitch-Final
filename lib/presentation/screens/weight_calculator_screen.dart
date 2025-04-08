import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/medicine_provider.dart'; // For medicine list
import '../bloc/dose_calculator_provider.dart'; // Import the provider
import '../bloc/subscription_provider.dart'; // Import Subscription Provider
import '../widgets/custom_search_delegate.dart'; // Import the search delegate

class WeightCalculatorScreen extends StatefulWidget {
  const WeightCalculatorScreen({super.key});

  @override
  State<WeightCalculatorScreen> createState() => _WeightCalculatorScreenState();
}

class _WeightCalculatorScreenState extends State<WeightCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers if provider has existing values (e.g., navigating back)
    final doseProvider = context.read<DoseCalculatorProvider>();
    _weightController.text = doseProvider.weight?.toString() ?? '';
    _ageController.text = doseProvider.age?.toString() ?? '';

    // Add listeners to update provider state immediately
    _weightController.addListener(() {
      context.read<DoseCalculatorProvider>().setWeight(_weightController.text);
    });
    _ageController.addListener(() {
      context.read<DoseCalculatorProvider>().setAge(_ageController.text);
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _calculate() {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      context.read<DoseCalculatorProvider>().calculateDose();
    }
  }

  // Function to show medicine search
  Future<void> _showMedicineSearch(
    BuildContext context,
    List<DrugEntity> medicines,
  ) async {
    final selectedDrug = await showSearch<DrugEntity?>(
      context: context,
      delegate: CustomSearchDelegate(
        searchFieldLabel: 'ابحث عن دواء...',
        medicines: medicines,
        searchLogic: (query) {
          if (query.isEmpty) {
            return medicines; // Show all if query is empty
          }
          final lowerCaseQuery = query.toLowerCase();
          return medicines.where((drug) {
            return drug.tradeName.toLowerCase().contains(lowerCaseQuery) ||
                drug.arabicName.toLowerCase().contains(lowerCaseQuery);
          }).toList();
        },
      ),
    );

    if (selectedDrug != null && context.mounted) {
      context.read<DoseCalculatorProvider>().setSelectedDrug(selectedDrug);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicineProvider = context.read<MedicineProvider>();
    final doseProvider = context.watch<DoseCalculatorProvider>();
    final subscriptionProvider =
        context.watch<SubscriptionProvider>(); // Watch subscription status
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Define card padding and margin
    const cardMargin = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
    const cardPadding = EdgeInsets.all(16.0);

    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة الجرعة')),
      body: SingleChildScrollView(
        // Make content scrollable
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input Card
              Card(
                margin: cardMargin,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Medicine Selection (Styled like a TextField)
                      InkWell(
                        borderRadius: BorderRadius.circular(8.0),
                        onTap:
                            () => _showMedicineSearch(
                              context,
                              medicineProvider.medicines,
                            ),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'الدواء',
                            hintText: 'اختر أو ابحث عن دواء',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 16.0,
                            ),
                            suffixIcon: const Icon(Icons.search, size: 20),
                          ),
                          child: Text(
                            doseProvider.selectedDrug?.tradeName ??
                                'لم يتم الاختيار',
                            style: textTheme.bodyLarge?.copyWith(
                              color:
                                  doseProvider.selectedDrug == null
                                      ? theme.hintColor
                                      : null,
                            ),
                          ),
                        ),
                      ),
                      // Validation message for drug selection
                      if (doseProvider.showDrugSelectionError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                          child: Text(
                            'يرجى اختيار دواء',
                            style: TextStyle(
                              color: colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16.0),

                      // Weight Input
                      TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: 'وزن المريض (كجم)',
                          hintText: 'أدخل الوزن بالكيلوجرام',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(
                            Icons.monitor_weight_outlined,
                            size: 20,
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
                              double.parse(value) <= 0) {
                            return 'وزن غير صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Age Input
                      TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: 'عمر المريض (سنوات)',
                          hintText: 'أدخل العمر بالسنوات',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'يرجى إدخال العمر';
                          if (int.tryParse(value) == null ||
                              int.parse(value) < 0) {
                            return 'عمر غير صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),

                      // Calculate Button
                      ElevatedButton.icon(
                        icon:
                            doseProvider.isLoading
                                ? Container(
                                  // Show progress indicator inside button
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                                : const Icon(Icons.calculate_outlined),
                        label: Text(
                          doseProvider.isLoading
                              ? 'جاري الحساب...'
                              : 'حساب الجرعة',
                        ),
                        onPressed:
                            doseProvider.isLoading
                                ? null
                                : _calculate, // Disable while loading
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          textStyle: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ), // End of Input Card

              const SizedBox(height: 16.0),

              // Result Display Area
              if (doseProvider.error.isNotEmpty)
                _buildErrorCard(context, doseProvider.error)
              else if (doseProvider.dosageResult != null)
                _buildResultCard(context, doseProvider),

              // Save Calculation Button (Premium Placeholder)
              if (doseProvider.dosageResult != null &&
                  doseProvider.error.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Consumer<SubscriptionProvider>(
                    // Use Consumer for reactivity
                    builder: (context, subProvider, child) {
                      bool canSave = subProvider.isPremiumUser;
                      return ElevatedButton.icon(
                        icon: Icon(
                          Icons.save_alt_outlined,
                          size: 20,
                          color:
                              canSave
                                  ? colorScheme.onSecondaryContainer
                                  : Colors.grey,
                        ),
                        label: Text(
                          'حفظ الحساب',
                          style: TextStyle(
                            color:
                                canSave
                                    ? colorScheme.onSecondaryContainer
                                    : Colors.grey,
                          ),
                        ),
                        onPressed:
                            canSave
                                ? () {
                                  // TODO: Implement actual save calculation logic
                                  print('Save calculation tapped (Premium)');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'سيتم إضافة حفظ الحساب لاحقاً.',
                                      ),
                                    ),
                                  );
                                }
                                : () {
                                  // Show premium required message if button is tapped when disabled
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'ميزة حفظ الحساب تتطلب اشتراك Premium.',
                                      ),
                                      action: SnackBarAction(
                                        label: 'اشترك الآن',
                                        onPressed: () {
                                          // TODO: Navigate to SubscriptionScreen
                                          print(
                                            'Navigate to Subscription Screen',
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          backgroundColor:
                              canSave
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.surfaceVariant,
                          foregroundColor:
                              canSave
                                  ? colorScheme.onSecondaryContainer
                                  : Colors.grey,
                          elevation: canSave ? 1 : 0,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for Error Card
  Widget _buildErrorCard(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'خطأ: $error',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for Result Card
  Widget _buildResultCard(
    BuildContext context,
    DoseCalculatorProvider doseProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final result = doseProvider.dosageResult!;
    final bool hasWarning =
        result.warning != null && result.warning!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color:
          hasWarning
              ? Colors.orange.shade50
              : colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الجرعة الموصى بها:',
              style: textTheme.titleMedium?.copyWith(
                color:
                    hasWarning ? Colors.orange.shade900 : colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              result.dosage,
              style: textTheme.headlineSmall?.copyWith(
                color:
                    hasWarning ? Colors.orange.shade900 : colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (result.notes != null && result.notes!.isNotEmpty) ...[
              const Divider(height: 24.0),
              Text(
                'ملاحظات:',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                result.notes!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (hasWarning) ...[
              const Divider(height: 24.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade800,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تحذير: ${result.warning!}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
