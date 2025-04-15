import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/medicine_provider.dart';
import 'section_header.dart'; // Use SectionHeader

class FilterBottomSheet extends StatefulWidget {
  final ScrollController scrollController;

  const FilterBottomSheet({super.key, required this.scrollController});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // Local state for temporary filter values
  late List<String> _tempSelectedCategories;
  late RangeValues _tempPriceRange;
  // Add other temp states if needed

  @override
  void initState() {
    super.initState();
    final provider = context.read<MedicineProvider>();
    // Initialize with single selection logic for now
    _tempSelectedCategories = List.from(
      provider.selectedCategory.isNotEmpty ? [provider.selectedCategory] : [],
    );
    _tempPriceRange =
        provider.selectedPriceRange ??
        RangeValues(provider.minPrice, provider.maxPrice);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MedicineProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final allCategories = provider.categories;

    return Padding(
      // Add padding around the content
      padding: const EdgeInsets.only(
        top: 8.0,
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: ListView(
        // Use ListView for scrolling content
        controller: widget.scrollController,
        children: [
          // Header with Title and Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'فلترة النتائج',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(LucideIcons.x, color: colorScheme.onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
                tooltip: 'إغلاق',
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 16), // Spacing after header
          // --- Categories Filter ---
          Text(
            'الفئات الطبية',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children:
                allCategories.map((category) {
                  final isSelected = _tempSelectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        // Single selection logic
                        if (selected) {
                          _tempSelectedCategories = [category];
                        } else {
                          _tempSelectedCategories = [];
                        }
                      });
                    },
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.onPrimaryContainer,
                    labelStyle: textTheme.labelLarge?.copyWith(
                      // Use labelLarge for better readability
                      color:
                          isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                    ),
                    backgroundColor: colorScheme.surfaceVariant.withOpacity(
                      0.5,
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(
                        color:
                            isSelected
                                ? Colors.transparent
                                : colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    showCheckmark: true, // Explicitly show checkmark
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ), // Adjust padding
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),

          // --- Price Range Filter ---
          Text(
            'نطاق السعر',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          RangeSlider(
            values: _tempPriceRange,
            min: provider.minPrice,
            max: provider.maxPrice,
            divisions:
                (provider.maxPrice > provider.minPrice)
                    ? 20
                    : null, // Avoid division by zero
            labels: RangeLabels(
              '${_tempPriceRange.start.round()} ج.م',
              '${_tempPriceRange.end.round()} ج.م',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                // Ensure start is not greater than end
                if (values.start <= values.end) {
                  _tempPriceRange = values;
                }
              });
            },
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.primary.withOpacity(0.3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
            ), // Add padding for labels
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_tempPriceRange.start.round()} ج.م',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${_tempPriceRange.end.round()} ج.م',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32), // More spacing before buttons
          // --- Action Buttons ---
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _tempSelectedCategories = [];
                      _tempPriceRange = RangeValues(
                        provider.minPrice,
                        provider.maxPrice,
                      );
                    });
                    provider.setCategory('');
                    provider.setPriceRange(null);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ), // Adjust button padding
                  ),
                  child: const Text('إعادة تعيين'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    provider.setCategory(
                      _tempSelectedCategories.isNotEmpty
                          ? _tempSelectedCategories.first
                          : '',
                    );
                    if (_tempPriceRange.start > provider.minPrice ||
                        _tempPriceRange.end < provider.maxPrice) {
                      provider.setPriceRange(_tempPriceRange);
                    } else {
                      provider.setPriceRange(null);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ), // Adjust button padding
                  ),
                  child: const Text('تطبيق الفلاتر'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // Bottom padding
        ],
      ),
    );
  }
}
