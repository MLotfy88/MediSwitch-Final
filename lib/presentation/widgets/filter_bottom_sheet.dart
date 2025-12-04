import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/currency_helper.dart';
import '../bloc/medicine_provider.dart';
// import 'section_header.dart'; // Not used directly in this layout

class FilterBottomSheet extends StatefulWidget {
  final ScrollController scrollController;

  const FilterBottomSheet({super.key, required this.scrollController});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // Local state for temporary filter values
  late String _tempSelectedCategory; // Back to String for single category
  late RangeValues _tempPriceRange;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MedicineProvider>();
    // Initialize with single category from provider
    _tempSelectedCategory = provider.selectedCategory;
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
      padding: const EdgeInsets.only(
        top: 8.0,
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      child: ListView(
        controller: widget.scrollController,
        children: [
          // Header
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
          const SizedBox(height: 24),

          // --- Categories Filter ---
          Text(
            'الفئات',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          // Use FilterChip again for single selection UI
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children:
                allCategories.map((category) {
                  final isSelected = _tempSelectedCategory == category;
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        // If selected, set it as the temp category. If deselected (tapped again), clear temp category.
                        _tempSelectedCategory = selected ? category : '';
                      });
                    },
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.onPrimaryContainer,
                    labelStyle: textTheme.labelLarge?.copyWith(
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
                    showCheckmark: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),

          // --- Price Range Filter ---
          Text(
            'نطاق السعر',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          RangeSlider(
            values: _tempPriceRange,
            min: provider.minPrice,
            max: provider.maxPrice,
            divisions: (provider.maxPrice > provider.minPrice) ? 20 : null,
            labels: RangeLabels(
              '${_tempPriceRange.start.round()} ${CurrencyHelper.getCurrencySymbol(context)}',
              '${_tempPriceRange.end.round()} ${CurrencyHelper.getCurrencySymbol(context)}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                if (values.start <= values.end) {
                  _tempPriceRange = values;
                }
              });
            },
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.primary.withOpacity(0.3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_tempPriceRange.start.round()} ${CurrencyHelper.getCurrencySymbol(context)}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_tempPriceRange.end.round()} ${CurrencyHelper.getCurrencySymbol(context)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- Action Buttons ---
          Row(
            children: [
              Expanded(
                // Reset Button
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _tempSelectedCategory = ''; // Reset local state
                      _tempPriceRange = RangeValues(
                        provider.minPrice,
                        provider.maxPrice,
                      );
                    });
                    // Apply reset to provider using single category method
                    provider.setCategory(''); // Use setCategory
                    provider.setPriceRange(null);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: colorScheme.onSurfaceVariant,
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  child: const Text('إعادة تعيين'),
                ),
              ),
              const SizedBox(width: 8), // gap-2
              Expanded(
                // Apply Button
                child: ElevatedButton(
                  onPressed: () {
                    // Apply temporary filters to the provider using single category method
                    provider.setCategory(
                      _tempSelectedCategory,
                    ); // Use setCategory
                    if (_tempPriceRange.start > provider.minPrice ||
                        _tempPriceRange.end < provider.maxPrice) {
                      provider.setPriceRange(_tempPriceRange);
                    } else {
                      provider.setPriceRange(null);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text('تطبيق الفلاتر'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
