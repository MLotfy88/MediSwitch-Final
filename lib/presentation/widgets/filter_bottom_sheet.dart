import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/medicine_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _tempSelectedCategory;
  String? _tempSelectedDosageForm; // State for dosage form
  RangeValues?
  _tempPriceRange; // State for price range (using RangeValues for flexibility)
  // TODO: Get actual min/max price from provider or data source
  final double _minPrice = 0;
  final double _maxPrice = 1000; // Placeholder max price

  @override
  void initState() {
    super.initState();
    // Initialize with current filters from the provider
    final provider = context.read<MedicineProvider>();
    _tempSelectedCategory = provider.selectedCategory;
    // TODO: Initialize dosage form and price range from provider if implemented
    _tempSelectedDosageForm = ''; // Default to 'All'
    _tempPriceRange = RangeValues(
      _minPrice,
      _maxPrice,
    ); // Default to full range
    // If provider has single price value, adjust initial range
    // if (provider.selectedPrice != null) {
    //   _tempPriceRange = RangeValues(_minPrice, provider.selectedPrice!);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final medicineProvider = context.watch<MedicineProvider>();
    final categories = ['', ...medicineProvider.categories]; // Add 'All' option
    // Placeholder dosage forms - replace with actual data later
    final dosageForms = ['', 'أقراص', 'كبسولات', 'شراب', 'حقن', 'كريم'];

    return Container(
      // Mimic .filter-content styling
      padding: const EdgeInsets.only(top: 8.0), // Padding for handle
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24.0),
        ), // .rounded-xl
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Take minimum height
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تصفية النتائج',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'إغلاق',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable Filter Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Filter
                  _buildFilterSection(
                    context,
                    'الفئة الرئيسية',
                    categories,
                    _tempSelectedCategory,
                    (value) => setState(() => _tempSelectedCategory = value),
                  ),
                  const SizedBox(height: 20),
                  // Dosage Form Filter
                  _buildFilterSection(
                    context,
                    'شكل الدواء',
                    dosageForms,
                    _tempSelectedDosageForm,
                    (value) => setState(() => _tempSelectedDosageForm = value),
                  ),
                  const SizedBox(height: 20),
                  // Price Filter
                  _buildPriceRangeSection(context),
                ],
              ),
            ),
          ),
          // Footer Buttons
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    // Reset temporary selections and apply
                    setState(() {
                      _tempSelectedCategory = '';
                      _tempSelectedDosageForm = '';
                      _tempPriceRange = RangeValues(_minPrice, _maxPrice);
                    });
                    // Apply reset filters immediately
                    // TODO: Add reset logic to provider if needed
                    context.read<MedicineProvider>().setCategory('');
                    // context.read<MedicineProvider>().setDosageForm(''); // Add if implemented
                    // context.read<MedicineProvider>().setPriceRange(null); // Add if implemented
                    // Navigator.pop(context); // Optionally close after reset
                  },
                  child: const Text('إعادة ضبط'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply the selected filters in the provider
                    // TODO: Add dosage form and price range filtering to provider
                    if (_tempSelectedCategory != null) {
                      context.read<MedicineProvider>().setCategory(
                        _tempSelectedCategory!,
                      );
                    }
                    // if (_tempSelectedDosageForm != null) {
                    //   context.read<MedicineProvider>().setDosageForm(_tempSelectedDosageForm!);
                    // }
                    // if (_tempPriceRange != null) {
                    //   context.read<MedicineProvider>().setPriceRange(_tempPriceRange!);
                    // }
                    Navigator.pop(context); // Close the bottom sheet
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('تطبيق'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build a filter section with chips
  Widget _buildFilterSection(
    BuildContext context,
    String title,
    List<String> options,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8.0),
        Wrap(
          // Use Wrap for chips
          spacing: 8.0,
          runSpacing: 8.0,
          children:
              options.map((option) {
                final isSelected = selectedValue == option;
                return FilterChip(
                  label: Text(option.isEmpty ? 'الكل' : option),
                  selected: isSelected,
                  onSelected: (selected) {
                    onChanged(
                      selected ? option : '',
                    ); // Pass empty string for 'All'
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color:
                          isSelected
                              ? Colors.transparent
                              : Theme.of(context).dividerColor,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  // Helper to build the price range slider section
  Widget _buildPriceRangeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نطاق السعر', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8.0),
        RangeSlider(
          values: _tempPriceRange ?? RangeValues(_minPrice, _maxPrice),
          min: _minPrice,
          max: _maxPrice,
          divisions: 20, // Optional: for discrete steps
          labels: RangeLabels(
            '${_tempPriceRange?.start.round() ?? _minPrice.round()} جنيه',
            '${_tempPriceRange?.end.round() ?? _maxPrice.round()} جنيه',
          ),
          onChanged: (values) {
            setState(() {
              _tempPriceRange = values;
            });
          },
          activeColor: Theme.of(context).colorScheme.primary,
          inactiveColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        Padding(
          // Add labels below slider
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_minPrice.round()} جنيه',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${_maxPrice.round()} جنيه',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
