import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/medicine_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  final ScrollController scrollController; // Accept scroll controller

  const FilterBottomSheet({super.key, required this.scrollController});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _tempSelectedCategory;
  String? _tempSelectedDosageForm; // State for dosage form
  RangeValues?
  _tempPriceRange; // State for price range (using RangeValues for flexibility)
  // Removed placeholder min/max price, will use provider's values

  @override
  void initState() {
    super.initState();
    // Initialize with current filters from the provider
    final provider = context.read<MedicineProvider>();
    _tempSelectedCategory = provider.selectedCategory;
    _tempSelectedDosageForm =
        provider.selectedDosageForm; // Initialize from provider
    _tempPriceRange =
        provider.selectedPriceRange ??
        RangeValues(
          provider.minPrice,
          provider.maxPrice,
        ); // Initialize from provider or full range
  }

  @override
  Widget build(BuildContext context) {
    final medicineProvider = context.watch<MedicineProvider>();
    final categories = ['', ...medicineProvider.categories]; // Add 'All' option
    // Placeholder dosage forms - replace with actual data later
    final dosageForms = ['', 'أقراص', 'كبسولات', 'شراب', 'حقن', 'كريم'];

    // Removed outer Container and Column. Use ListView directly with the passed controller.
    return ListView(
      controller: widget.scrollController, // Use the passed controller
      children: [
        // Drag Handle (Keep this at the top)
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(
              vertical: 12.0,
            ), // Adjusted margin
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
            vertical: 0.0, // Reduced vertical padding
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
        const Divider(height: 1), // Keep divider
        // Filter Sections (Wrap content in Padding)
        Padding(
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
              // Price Filter - Pass the provider
              _buildPriceRangeSection(context, medicineProvider),
            ],
          ),
        ),

        // Footer Buttons (Keep this at the bottom, outside the inner padding)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reset Button (Ghost style)
              TextButton(
                onPressed: () {
                  // Reset temporary selections
                  setState(() {
                    _tempSelectedCategory = '';
                    _tempSelectedDosageForm = '';
                    // Use provider's min/max for reset state
                    _tempPriceRange = RangeValues(
                      medicineProvider.minPrice,
                      medicineProvider.maxPrice,
                    );
                  });
                  // Apply reset filters immediately in provider
                  final provider = context.read<MedicineProvider>();
                  provider.setCategory('');
                  provider.setDosageForm(''); // Reset dosage form
                  provider.setPriceRange(null); // Reset price range
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant, // Muted color
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text('إعادة ضبط'),
              ),
              // Apply Button (Default style)
              ElevatedButton(
                onPressed: () {
                  // Apply the selected filters in the provider
                  final provider = context.read<MedicineProvider>();
                  // Apply all temporary filters
                  provider.setCategory(_tempSelectedCategory ?? '');
                  provider.setDosageForm(_tempSelectedDosageForm ?? '');
                  // Apply price range only if it's different from the full range
                  if (_tempPriceRange != null &&
                      (_tempPriceRange!.start >
                              provider
                                  .minPrice || // Check if start is greater than min
                          _tempPriceRange!.end < provider.maxPrice)) {
                    // Check if end is less than max
                    provider.setPriceRange(_tempPriceRange);
                  } else {
                    provider.setPriceRange(
                      null,
                    ); // Treat as no price filter if full range selected
                  }
                  Navigator.pop(context); // Close the bottom sheet
                },
                // Apply Button (Default style)
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    // Match shadcn border radius
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ), // Slightly bolder
                ),
                child: const Text('تطبيق'),
              ),
            ],
          ),
        ),
      ],
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
                // Use ChoiceChip for single selection behavior
                return ChoiceChip(
                  label: Text(option.isEmpty ? 'الكل' : option),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      // Only update if selected is true
                      onChanged(option);
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant, // Use onSurfaceVariant for unselected
                    // fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, // Default weight is usually fine
                  ),
                  // checkmarkColor: Theme.of(context).colorScheme.onPrimary, // Usually not needed for ChoiceChip
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color:
                          isSelected
                              ? Colors.transparent
                              : Theme.of(context).dividerColor.withOpacity(
                                0.5,
                              ), // Make border subtle
                    ),
                  ),
                  showCheckmark:
                      false, // Typically don't show checkmark for this style
                  pressElevation: 1,
                );
              }).toList(),
        ),
      ],
    );
  }

  // Helper to build the price range slider section
  // Now accepts MedicineProvider
  Widget _buildPriceRangeSection(
    BuildContext context,
    MedicineProvider medicineProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('نطاق السعر', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8.0),
        RangeSlider(
          // Use min/max from provider
          values:
              _tempPriceRange ??
              RangeValues(medicineProvider.minPrice, medicineProvider.maxPrice),
          min: medicineProvider.minPrice,
          max: medicineProvider.maxPrice,
          divisions: 20, // Optional: for discrete steps
          labels: RangeLabels(
            // Use provider values for labels if temp range is null
            '${_tempPriceRange?.start.round() ?? medicineProvider.minPrice.round()} جنيه',
            '${_tempPriceRange?.end.round() ?? medicineProvider.maxPrice.round()} جنيه',
          ),
          onChanged: (values) {
            // Ensure values don't exceed provider's min/max (safety check)
            final validStart = values.start.clamp(
              medicineProvider.minPrice,
              medicineProvider.maxPrice,
            );
            final validEnd = values.end.clamp(
              medicineProvider.minPrice,
              medicineProvider.maxPrice,
            );
            // Ensure start is not greater than end after clamping
            final adjustedEnd = validEnd < validStart ? validStart : validEnd;

            setState(() {
              _tempPriceRange = RangeValues(validStart, adjustedEnd);
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
                // Use provider values for min/max labels
                '${medicineProvider.minPrice.round()} جنيه',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${medicineProvider.maxPrice.round()} جنيه',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
