import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/medicine_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _tempSelectedCategory; // Temporarily store selection

  @override
  void initState() {
    super.initState();
    // Initialize with the current category from the provider
    _tempSelectedCategory = context.read<MedicineProvider>().selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final medicineProvider = context.watch<MedicineProvider>();
    final categories = medicineProvider.categories;
    final currentCategory = medicineProvider.selectedCategory;

    // Update temp selection if provider changes externally (less likely here)
    // This ensures the radio button reflects the actual state if sheet is rebuilt
    if (_tempSelectedCategory != currentCategory &&
        categories.contains(currentCategory)) {
      _tempSelectedCategory = currentCategory;
    } else if (!categories.contains(_tempSelectedCategory) &&
        _tempSelectedCategory != '') {
      // If the temp category is no longer valid (e.g., data reloaded), reset it
      _tempSelectedCategory = '';
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white, // Or use Theme color
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take minimum height
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            // Handle for dragging
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'فلترة حسب الفئة',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10.0),
          Expanded(
            // Allow list to scroll if many categories
            child: ListView(
              shrinkWrap: true,
              children: [
                // Option for "All"
                RadioListTile<String>(
                  title: const Text('الكل'),
                  value: '', // Represent "All" with empty string
                  groupValue: _tempSelectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _tempSelectedCategory = value;
                    });
                  },
                ),
                // Options for each category
                ...categories.map((category) {
                  return RadioListTile<String>(
                    title: Text(category),
                    value: category,
                    groupValue: _tempSelectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _tempSelectedCategory = value;
                      });
                    },
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16.0),
          // Apply Button
          Center(
            child: ElevatedButton(
              onPressed: () {
                // Apply the selected category in the provider
                if (_tempSelectedCategory != null) {
                  context.read<MedicineProvider>().setCategory(
                    _tempSelectedCategory!,
                  );
                }
                Navigator.pop(context); // Close the bottom sheet
              },
              child: const Text('تطبيق'),
            ),
          ),
          const SizedBox(height: 8.0), // Padding at the bottom
        ],
      ),
    );
  }
}
