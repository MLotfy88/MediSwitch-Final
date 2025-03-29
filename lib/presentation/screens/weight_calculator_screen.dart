import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/medicine_provider.dart'; // Corrected provider path

class WeightCalculatorScreen extends StatefulWidget {
  const WeightCalculatorScreen({super.key});

  @override
  State<WeightCalculatorScreen> createState() => _WeightCalculatorScreenState();
}

class _WeightCalculatorScreenState extends State<WeightCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  DrugEntity? _selectedMedicine; // Corrected type
  final TextEditingController _weightController = TextEditingController();
  String? _calculatedDose; // To store the result
  bool _showWarning = false; // To show overdose warning

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  // Placeholder function for dose calculation
  // TODO: Implement actual logic using UseCases and potentially drug-specific data
  void _calculateDose() {
    if (_formKey.currentState!.validate() && _selectedMedicine != null) {
      final weight = double.tryParse(_weightController.text);
      if (weight == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('يرجى إدخال وزن صحيح')));
        return;
      }

      // --- Placeholder Calculation Logic ---
      // This needs significant refinement based on actual drug data and formulas.
      // Assumes a simple mg/kg calculation for demonstration.
      // Needs access to drug concentration/strength from DrugEntity (add this field later).
      double dosePerKg = 5; // DUMMY VALUE - Replace with actual data lookup
      double maxDailyDose =
          100; // DUMMY VALUE - Replace with actual data lookup

      final calculated = weight * dosePerKg;
      final warning = calculated > maxDailyDose;
      // --- End Placeholder Calculation Logic ---

      setState(() {
        // Format the result (e.g., "50 mg") - needs unit from drug data
        _calculatedDose =
            '${calculated.toStringAsFixed(1)} مجم (مثال)'; // DUMMY UNIT
        _showWarning = warning;
      });

      // Optional: Play warning sound if _showWarning is true
      // if (_showWarning) {
      //   // Use audioplayers or similar package
      // }
    } else if (_selectedMedicine == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى اختيار دواء أولاً')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicineProvider = context.read<MedicineProvider>();

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
                  _selectedMedicine == null
                      ? 'اختر الدواء'
                      : _selectedMedicine!.tradeName,
                ), // Use DrugEntity field
                subtitle:
                    _selectedMedicine == null
                        ? null
                        : Text(
                          _selectedMedicine!.arabicName,
                        ), // Use DrugEntity field
                trailing: const Icon(Icons.arrow_drop_down),
                onTap: () async {
                  final selected = await _showMedicineSelectionDialog(
                    context,
                    medicineProvider.medicines, // Pass List<DrugEntity>
                  );
                  if (selected != null) {
                    setState(() {
                      _selectedMedicine = selected;
                      _calculatedDose =
                          null; // Reset calculation on new drug selection
                      _showWarning = false;
                    });
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
              const SizedBox(height: 24.0),

              // Calculate Button
              ElevatedButton.icon(
                icon: const Icon(Icons.calculate),
                label: const Text('حساب الجرعة'),
                onPressed: _calculateDose,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
              const SizedBox(height: 24.0),

              // Result Display
              if (_calculatedDose != null)
                Card(
                  elevation: 2,
                  color:
                      _showWarning
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'الجرعة المحسوبة:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                _showWarning
                                    ? Colors.red.shade900
                                    : Colors.green.shade900,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          _calculatedDose!,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                _showWarning
                                    ? Colors.red.shade900
                                    : Colors.green.shade900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_showWarning) ...[
                          const SizedBox(height: 8.0),
                          Text(
                            'تحذير: الجرعة المحسوبة قد تتجاوز الحد الأقصى الموصى به!',
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
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
