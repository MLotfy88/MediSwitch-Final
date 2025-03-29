import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../main.dart'; // Access MedicineProvider

class WeightCalculatorScreen extends StatefulWidget {
  const WeightCalculatorScreen({super.key});

  @override
  State<WeightCalculatorScreen> createState() => _WeightCalculatorScreenState();
}

class _WeightCalculatorScreenState extends State<WeightCalculatorScreen> {
  Medicine? _selectedMedicine;
  final TextEditingController _weightController = TextEditingController();
  // TODO: Add age input if needed for calculations
  String _calculatedDose = ''; // Placeholder for results
  bool _isLoading = false;
  String _weightUnit = 'kg'; // Default unit

  // TODO: Implement dose calculation logic

  void _calculateDose() async {
    if (_selectedMedicine == null || _weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار دواء وإدخال وزن المريض')),
      );
      return;
    }

    final double? weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال وزن صحيح')));
      return;
    }

    // Convert weight to kg if needed
    final weightInKg = (_weightUnit == 'lb') ? weight * 0.453592 : weight;

    setState(() {
      _isLoading = true;
      _calculatedDose = ''; // Clear previous results
    });

    // --- Placeholder Logic ---
    // In a real implementation, you would:
    // 1. Get dosage information for the _selectedMedicine (likely needs parsing from its description or specific fields if available in CSV).
    // 2. Perform calculation based on weightInKg (and potentially age).
    // 3. Handle different units and formulations.
    // 4. Implement safety checks for max dosage.
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate calculation delay
    // Example result (replace with actual logic)
    _calculatedDose =
        'الجرعة المحسوبة: ${(weightInKg * 10).toStringAsFixed(1)} mg/day (مثال)'; // Example calculation
    // --- End Placeholder Logic ---

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حاسبة الجرعة بالوزن')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Added for smaller screens
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // TODO: Implement a better Medicine selection widget
              Text(
                'الدواء: ${_selectedMedicine?.tradeName ?? "لم يتم الاختيار"}',
              ),
              ElevatedButton(
                onPressed: () async {
                  final medicineProvider = Provider.of<MedicineProvider>(
                    context,
                    listen: false,
                  );
                  final selected = await _showMedicineSelectionDialog(
                    context,
                    medicineProvider.medicines,
                  );
                  if (selected != null) {
                    setState(() {
                      _selectedMedicine = selected;
                    });
                  }
                },
                child: const Text('اختر الدواء'),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: 'وزن المريض',
                        hintText: 'أدخل الوزن',
                        border: const OutlineInputBorder(),
                        suffixText: _weightUnit,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _weightUnit,
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'lb', child: Text('lb')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _weightUnit = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              // TODO: Add Age Input Field if required
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _calculateDose,
                child: const Text('احسب الجرعة'),
              ),
              const SizedBox(height: 24.0),
              const Text(
                'الجرعة المقترحة:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_calculatedDose.isEmpty)
                const Center(child: Text('أدخل البيانات لحساب الجرعة.'))
              else
                Center(
                  child: Text(
                    _calculatedDose,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blueAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // TODO: Add warnings for exceeding safe dosage
            ],
          ),
        ),
      ),
    );
  }

  // Helper to show a simple dialog for medicine selection (Duplicate from DoseComparisonScreen - consider refactoring to a shared widget)
  Future<Medicine?> _showMedicineSelectionDialog(
    BuildContext context,
    List<Medicine> medicines,
  ) async {
    return showDialog<Medicine>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('اختر دواء'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: medicines.length > 20 ? 20 : medicines.length,
              itemBuilder: (context, index) {
                final med = medicines[index];
                return ListTile(
                  title: Text(med.tradeName),
                  subtitle: Text(med.arabicName),
                  onTap: () {
                    Navigator.of(context).pop(med);
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
