import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:provider/provider.dart';
import '../bloc/dose_calculator_provider.dart'; // Import the provider
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity for selected drug state
import '../widgets/drug_search_delegate.dart'; // Import the search delegate

// Renamed class to match the file name and usage in main_screen.dart
class DoseComparisonScreen extends StatefulWidget {
  const DoseComparisonScreen({super.key});

  @override
  State<DoseComparisonScreen> createState() => _DoseComparisonScreenState();
}

// Renamed state class
class _DoseComparisonScreenState extends State<DoseComparisonScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _drugSearchController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  DrugEntity? _selectedDrug;

  @override
  void dispose() {
    _drugSearchController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the provider instance
    final doseProvider = context.watch<DoseCalculatorProvider>();

    return Scaffold(
      // Changed AppBar title to reflect comparison screen purpose
      appBar: AppBar(title: const Text('مقارنة الجرعات'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drug Selection Input
                    const Text(
                      'الدواء:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _drugSearchController,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن اسم الدواء...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      readOnly: true,
                      onTap: () async {
                        // Show the search delegate
                        final selected = await showSearch<DrugEntity?>(
                          context: context,
                          delegate: DrugSearchDelegate(),
                          // query: _drugSearchController.text, // Optionally pre-fill query
                        );

                        // Handle the selected drug (if any)
                        if (selected != null && mounted) {
                          setState(() {
                            _selectedDrug = selected;
                            _drugSearchController.text =
                                selected.tradeName; // Or arabicName
                          });
                          // Update the provider with the selected drug
                          context
                              .read<DoseCalculatorProvider>()
                              .setSelectedDrug(selected);
                        }
                      },
                      validator: (value) {
                        // Validation remains the same
                        if (_selectedDrug == null) {
                          return 'يرجى اختيار دواء';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Patient Weight Input
                    const Text(
                      'وزن المريض (كجم):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        hintText: 'أدخل وزن المريض بالكيلوجرام',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixText: 'كجم',
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ), // Closing parenthesis for allow
                      ], // Closing bracket for list
                      onChanged: (value) {
                        // Update provider state
                        context.read<DoseCalculatorProvider>().setWeight(value);
                      },
                      validator: (value) {
                        // Keep existing validation, provider handles logic on calculate
                        if (value == null || value.isEmpty) {
                          return 'يرجى إدخال الوزن';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight <= 0) {
                          return 'الوزن غير صالح';
                        }
                        return null;
                      },
                    ), // Closing parenthesis for weight TextFormField
                    const SizedBox(height: 32),

                    // Calculate Button (Title might change depending on screen purpose)
                    ElevatedButton(
                      // Disable button while loading
                      onPressed:
                          doseProvider.isLoading
                              ? null
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  print(
                                    'Calculate/Compare button pressed - Form is valid',
                                  );
                                  // Trigger calculation logic in provider
                                  context
                                      .read<DoseCalculatorProvider>()
                                      .calculateDose();
                                } else {
                                  print(
                                    'Calculate/Compare button pressed - Form is invalid',
                                  );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      // Changed button text to reflect comparison screen
                      // Show loading indicator on button if loading
                      child:
                          doseProvider.isLoading
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('قارن الجرعات / احسب'),
                    ),
                    const SizedBox(height: 16), // Reduced spacing slightly
                    // Save Calculation Button (Premium - Disabled for now)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.save_alt, size: 18),
                      label: const Text('حفظ الحساب (Premium)'),
                      onPressed: null, // Disabled for now
                      // onPressed: () {
                      //   // TODO: Implement Premium check and save logic (Task 3.3.6)
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     const SnackBar(content: Text('ميزة الحفظ متاحة في الإصدار المدفوع.')),
                      //   );
                      // },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.5),
                        ),
                        foregroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Results Section ---
                    const Text(
                      'النتيجة:', // Title might change
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Display Error if any
                    if (doseProvider.error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          doseProvider.error,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Display Calculated Dose
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity, // Take full width
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          doseProvider.calculatedDose != null
                              ? '${doseProvider.calculatedDose!.toStringAsFixed(2)}' // Format dose
                              : 'ستظهر نتيجة المقارنة / الحساب هنا...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // TODO: Add warning display area
                  ],
                ),
              ), // Closing Form
            ],
          ),
        ),
      ),
    );
  }
}
