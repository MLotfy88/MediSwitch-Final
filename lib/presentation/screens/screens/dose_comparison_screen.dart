import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../main.dart'; // Access MedicineProvider

class DoseComparisonScreen extends StatefulWidget {
  const DoseComparisonScreen({super.key});

  @override
  State<DoseComparisonScreen> createState() => _DoseComparisonScreenState();
}

class _DoseComparisonScreenState extends State<DoseComparisonScreen> {
  Medicine? _selectedMedicine;
  String _currentDose = '';
  List<Medicine> _alternatives = []; // Placeholder for results
  bool _isLoading = false;

  // TODO: Implement logic to find alternatives and calculate similarity

  void _findAlternatives() async {
    if (_selectedMedicine == null || _currentDose.isEmpty) {
      // Show error or prompt user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار دواء وإدخال الجرعة')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _alternatives = []; // Clear previous results
    });

    // --- Placeholder Logic ---
    // In a real implementation, you would:
    // 1. Parse _currentDose (handle units if necessary).
    // 2. Call a service method (e.g., in CsvService or a new service)
    //    that takes _selectedMedicine and parsed dose.
    // 3. The service method would find medicines with the same active ingredient
    //    or similar therapeutic category from the CSV data.
    // 4. Calculate equivalent doses and similarity percentages.
    // 5. Return a list of alternative Medicine objects with comparison info.
    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network/processing delay
    // Example results (replace with actual logic)
    final allMedicines =
        Provider.of<MedicineProvider>(context, listen: false).medicines;
    _alternatives =
        allMedicines
            .where(
              (med) =>
                  med.active == _selectedMedicine!.active &&
                  med.tradeName != _selectedMedicine!.tradeName,
            )
            .take(5) // Limit results for example
            .toList();
    // --- End Placeholder Logic ---

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using Consumer to get access to the provider's data if needed for selection
    return Scaffold(
      appBar: AppBar(title: const Text('مقارنة الجرعات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TODO: Implement a better Medicine selection widget (e.g., Searchable Dropdown)
            Text(
              'الدواء الأصلي: ${_selectedMedicine?.tradeName ?? "لم يتم الاختيار"}',
            ),
            ElevatedButton(
              onPressed: () async {
                // Simple selection for now, replace with a proper search/select dialog
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
              child: const Text('اختر الدواء الأصلي'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              decoration: const InputDecoration(
                labelText: 'الجرعة الحالية',
                hintText: 'مثال: 500mg',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text, // Adjust as needed
              onChanged: (value) {
                _currentDose = value;
              },
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _findAlternatives,
              child: const Text('ابحث عن بدائل'),
            ),
            const SizedBox(height: 24.0),
            const Text(
              'البدائل المقترحة:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_alternatives.isEmpty)
              const Center(
                child: Text('لا توجد بدائل مقترحة أو لم يتم البحث بعد.'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _alternatives.length,
                  itemBuilder: (context, index) {
                    final alt = _alternatives[index];
                    // TODO: Display similarity percentage and equivalent dose
                    return ListTile(
                      title: Text(alt.tradeName),
                      subtitle: Text(
                        'المادة الفعالة: ${alt.active} - السعر: ${alt.price}',
                      ),
                      // Add trailing info for similarity/dose
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper to show a simple dialog for medicine selection (Replace with better UI)
  Future<Medicine?> _showMedicineSelectionDialog(
    BuildContext context,
    List<Medicine> medicines,
  ) async {
    return showDialog<Medicine>(
      context: context,
      builder: (BuildContext context) {
        // Use a StatefulWidget inside the dialog to handle search state
        return AlertDialog(
          title: const Text('اختر دواء'),
          content: SizedBox(
            // Constrain size
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true, // Important for AlertDialog content
              itemCount:
                  medicines.length > 20
                      ? 20
                      : medicines.length, // Limit initial display
              itemBuilder: (context, index) {
                final med = medicines[index];
                return ListTile(
                  title: Text(med.tradeName),
                  subtitle: Text(med.arabicName),
                  onTap: () {
                    Navigator.of(context).pop(med); // Return selected medicine
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                Navigator.of(context).pop(); // Return null
              },
            ),
          ],
        );
      },
    );
  }
}
