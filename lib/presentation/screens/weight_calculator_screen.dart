import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:flutter/scheduler.dart'; // For post frame callback
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/medicine_provider.dart'; // For medicine list
import '../bloc/dose_calculator_provider.dart'; // Import the provider

class WeightCalculatorScreen extends StatefulWidget {
  const WeightCalculatorScreen({super.key});

  @override
  State<WeightCalculatorScreen> createState() => _WeightCalculatorScreenState();
}

class _WeightCalculatorScreenState extends State<WeightCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  // Use controllers, but state will be managed by provider
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController =
      TextEditingController(); // Added age controller

  // No need for local state for result/warning anymore

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose(); // Dispose age controller
    super.dispose();
  }

  // Removed local _calculateDose method, will use provider's method

  @override
  Widget build(BuildContext context) {
    // Access both providers
    final medicineProvider = context.read<MedicineProvider>();
    final doseProvider =
        context.watch<DoseCalculatorProvider>(); // Watch for UI updates

    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة الجرعة بالوزن')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Medicine Selection
              ListTile(
                title: Text(
                  doseProvider.selectedDrug == null
                      ? 'اختر الدواء'
                      : doseProvider.selectedDrug!.tradeName,
                ),
                subtitle:
                    doseProvider.selectedDrug == null
                        ? null
                        : Text(doseProvider.selectedDrug!.arabicName),
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final selected = await _showMedicineSelectionDialog(
                    context,
                    medicineProvider.medicines, // Pass List<DrugEntity>
                  );
                  if (selected != null) {
                    // Use provider to set the drug
                    context.read<DoseCalculatorProvider>().setSelectedDrug(
                      selected,
                    );
                  }
                },
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(height: 16.0),

              // Weight Input
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  // Removed const
                  labelText: 'وزن المريض (كجم)',
                  hintText: 'أدخل وزن المريض بالكيلوجرام',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ), // Allow numbers and decimals
                ],
                onChanged:
                    (value) =>
                        context.read<DoseCalculatorProvider>().setWeight(value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال الوزن';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'يرجى إدخال وزن صحيح أكبر من صفر';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0), // Space before Age Input
              // Age Input (New)
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  // Removed const
                  labelText: 'عمر المريض (سنوات)',
                  hintText: 'أدخل عمر المريض بالسنوات',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
                ],
                onChanged:
                    (value) =>
                        context.read<DoseCalculatorProvider>().setAge(value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال العمر';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'يرجى إدخال عمر صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),

              // Calculate Button
              ElevatedButton.icon(
                icon: const Icon(Icons.calculate),
                label: const Text('حساب الجرعة'),
                onPressed: () {
                  // Validate form before calculating
                  if (_formKey.currentState!.validate()) {
                    context.read<DoseCalculatorProvider>().calculateDose();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
              const SizedBox(height: 24.0),

              // Result Display
              // Result Display Area (Refactored)
              if (doseProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (doseProvider.error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'خطأ: ${doseProvider.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (doseProvider.dosageResult != null)
                Card(
                  elevation: 2,
                  color:
                      doseProvider.dosageResult!.warning != null
                          ? Colors
                              .orange
                              .shade100 // Warning color
                          : Colors.green.shade100, // Success color
                  margin: const EdgeInsets.only(top: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'الجرعة الموصى بها:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                doseProvider.dosageResult!.warning != null
                                    ? Colors.orange.shade900
                                    : Colors.green.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          doseProvider.dosageResult!.dosage,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                doseProvider.dosageResult!.warning != null
                                    ? Colors.orange.shade900
                                    : Colors.green.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (doseProvider.dosageResult!.notes != null &&
                            doseProvider.dosageResult!.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12.0),
                          Text(
                            'ملاحظات:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            doseProvider.dosageResult!.notes!,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                        if (doseProvider.dosageResult!.warning != null &&
                            doseProvider.dosageResult!.warning!.isNotEmpty) ...[
                          const SizedBox(height: 12.0),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4.0),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              'تحذير:\n${doseProvider.dosageResult!.warning!}',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to show medicine selection dialog - adjusted for DrugEntity
  Future<DrugEntity?> _showMedicineSelectionDialog(
    // Corrected return type
    BuildContext context,
    List<DrugEntity> medicines, // Corrected parameter type
  ) async {
    // Simple dialog for now, consider adding search later
    return showDialog<DrugEntity>(
      // Corrected dialog type
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر دواء'),
          content: SizedBox(
            width: double.maxFinite,
            // Make list scrollable if many items
            child: ListView.builder(
              shrinkWrap: true, // Important for AlertDialog content
              itemCount: medicines.length,
              itemBuilder: (BuildContext context, int index) {
                final drug = medicines[index]; // DrugEntity
                return ListTile(
                  title: Text(drug.tradeName), // Use DrugEntity field
                  subtitle: Text(drug.arabicName), // Use DrugEntity field
                  onTap: () {
                    Navigator.of(context).pop(drug); // Return DrugEntity
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop(); // Return null on cancel
              },
            ),
          ],
        );
      },
    );
  }
}
