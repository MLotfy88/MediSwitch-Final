import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/medicine_model.dart'; // Keep temporarily if needed for selection dialog? No, use Entity.
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/medicine_provider.dart'; // Corrected provider path

class DoseComparisonScreen extends StatefulWidget {
  const DoseComparisonScreen({super.key});

  @override
  State<DoseComparisonScreen> createState() => _DoseComparisonScreenState();
}

class _DoseComparisonScreenState extends State<DoseComparisonScreen> {
  DrugEntity? _selectedMedicine; // Corrected type
  final TextEditingController _doseController = TextEditingController();
  List<DrugEntity> _alternatives =
      []; // Placeholder for results - Corrected type
  bool _isLoadingAlternatives = false;

  @override
  void dispose() {
    _doseController.dispose();
    super.dispose();
  }

  // Placeholder function to find alternatives
  // TODO: Implement actual logic using UseCases and Repository
  void _findAlternatives() {
    if (_selectedMedicine == null || _doseController.text.isEmpty) {
      // Show error or return if input is missing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار دواء وإدخال الجرعة')),
      );
      return;
    }

    setState(() {
      _isLoadingAlternatives = true;
      _alternatives = []; // Clear previous results
    });

    // --- Placeholder Logic ---
    // In a real app, this would involve:
    // 1. Getting the active ingredient and strength/concentration of _selectedMedicine.
    // 2. Calling a UseCase (e.g., FindAlternativesUseCase).
    // 3. The UseCase calls the Repository.
    // 4. The Repository queries the data source (local/remote) for drugs with the same active ingredient.
    // 5. Filter/rank results based on dosage form, strength, price, etc.
    // 6. Return the list of DrugEntity alternatives.

    // Simulate a delay and return some dummy data for now
    Future.delayed(const Duration(seconds: 1), () {
      // Accessing provider to get the full list (temporary workaround)
      final allDrugs =
          context.read<MedicineProvider>().medicines; // Now List<DrugEntity>
      setState(() {
        // Dummy filter: find drugs with the same main category (very basic example)
        _alternatives =
            allDrugs
                .where(
                  (med) =>
                      med.mainCategory ==
                          _selectedMedicine!
                              .mainCategory && // Use DrugEntity field
                      med.tradeName != _selectedMedicine!.tradeName,
                ) // Exclude the original
                .take(5) // Limit results for demo
                .toList();
        _isLoadingAlternatives = false;
      });
    });
    // --- End Placeholder Logic ---
  }

  @override
  Widget build(BuildContext context) {
    // Access provider only once if not watching specific changes
    final medicineProvider = context.read<MedicineProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('مقارنة الجرعات والبدائل')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Medicine Selection
            ListTile(
              title: Text(
                _selectedMedicine == null
                    ? 'اختر الدواء الأصلي'
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
                // Show selection dialog - needs DrugEntity list
                final selected = await _showMedicineSelectionDialog(
                  context,
                  medicineProvider.medicines, // Pass List<DrugEntity>
                );
                if (selected != null) {
                  setState(() {
                    _selectedMedicine = selected;
                  });
                }
              },
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            const SizedBox(height: 16.0),

            // Dose Input
            TextField(
              controller: _doseController,
              decoration: InputDecoration(
                labelText: 'الجرعة الحالية للدواء الأصلي',
                hintText: 'مثال: 500 مجم أو 10 مل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              keyboardType: TextInputType.text, // Adjust as needed
            ),
            const SizedBox(height: 24.0),

            // Find Alternatives Button
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('إيجاد البدائل'),
              onPressed: _isLoadingAlternatives ? null : _findAlternatives,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
              ),
            ),
            const SizedBox(height: 24.0),

            // Alternatives List
            const Text(
              'البدائل المقترحة:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (_isLoadingAlternatives)
              const Center(child: CircularProgressIndicator())
            else if (_alternatives.isEmpty)
              const Center(child: Text('لا توجد بدائل متاحة حالياً.'))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _alternatives.length,
                  itemBuilder: (context, index) {
                    final alternative = _alternatives[index]; // DrugEntity
                    return Card(
                      child: ListTile(
                        title: Text(
                          alternative.tradeName,
                        ), // Use DrugEntity field
                        subtitle: Text(
                          'السعر: ${alternative.price} جنيه\nالفئة: ${alternative.mainCategory}',
                        ), // Use DrugEntity fields
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
          ],
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
    return showDialog<DrugEntity>(
      // Corrected dialog type
      context: context,
      builder: (BuildContext context) {
        // Use a StatefulWidget for search functionality within the dialog
        return AlertDialog(
          title: const Text('اختر دواء'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
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
