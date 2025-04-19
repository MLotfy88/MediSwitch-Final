import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/medicine_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import '../../core/constants/app_constants.dart'; // Import constants for translation map

class FilterEndDrawer extends StatefulWidget {
  const FilterEndDrawer({super.key});

  @override
  State<FilterEndDrawer> createState() => _FilterEndDrawerState();
}

class _FilterEndDrawerState extends State<FilterEndDrawer> {
  // Local state for temporary filter values
  late String _tempSelectedCategory;
  late RangeValues _tempPriceRange;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to access provider safely after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MedicineProvider>();
        // Initialize with provider's current values
        _tempSelectedCategory = provider.selectedCategory;
        _tempPriceRange =
            provider.selectedPriceRange ??
            RangeValues(provider.minPrice, provider.maxPrice);
        // Force rebuild if initial values differ (e.g., drawer opened before provider loaded)
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations instance
    final provider = context.watch<MedicineProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final allCategories = provider.categories;

    // Ensure state is initialized before building UI that depends on it
    // This check might be redundant due to addPostFrameCallback, but safe to keep
    // Check if _tempPriceRange is initialized before accessing start/end
    if (!mounted ||
        !this.isStateInitialized ||
        !(_tempPriceRange.start <= _tempPriceRange.end)) {
      // Show a loading or empty state if not initialized
      return const Drawer(child: Center(child: CircularProgressIndicator()));
    }

    return Drawer(
      width: 320, // w-80 equivalent (adjust as needed)
      child: SafeArea(
        // Ensure content doesn't overlap status bar etc.
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.filterResultsTitle, // Use localized string
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      LucideIcons.x,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(context), // Close drawer
                    tooltip: l10n.closeTooltip, // Use localized string
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(), // Add a divider
              const SizedBox(height: 16),

              Expanded(
                // Make the filter content scrollable
                child: ListView(
                  children: [
                    // --- Categories Filter ---
                    Text(
                      l10n.categoriesSectionTitle, // Use localized string
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children:
                          allCategories.map((category) {
                            final isSelected =
                                _tempSelectedCategory == category;
                            return FilterChip(
                              label: Text(
                                kCategoryTranslation[category] ??
                                    category, // Use translated category name
                              ), // Category names might need localization too if they are keys
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _tempSelectedCategory =
                                      selected ? category : '';
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
                              backgroundColor: colorScheme.surfaceVariant
                                  .withOpacity(0.5),
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color:
                                      isSelected
                                          ? Colors.transparent
                                          : colorScheme.outline.withOpacity(
                                            0.5,
                                          ),
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
                      l10n.priceRangeSectionTitle, // Use localized string
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RangeSlider(
                      values: _tempPriceRange,
                      min: provider.minPrice,
                      max: provider.maxPrice,
                      divisions:
                          (provider.maxPrice > provider.minPrice) ? 20 : null,
                      labels: RangeLabels(
                        l10n.priceRangeLabel(
                          _tempPriceRange.start.round().toString(),
                        ), // Use localized string
                        l10n.priceRangeLabel(
                          _tempPriceRange.end.round().toString(),
                        ), // Use localized string
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
                            l10n.priceRangeLabel(
                              _tempPriceRange.start.round().toString(),
                            ), // Use localized string
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            l10n.priceRangeLabel(
                              _tempPriceRange.end.round().toString(),
                            ), // Use localized string
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),

              // --- Action Buttons (Fixed at bottom) ---
              const Divider(), // Divider before buttons
              const SizedBox(height: 8),
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
                        // Apply reset to provider
                        provider.setCategory('');
                        provider.setPriceRange(null);
                        Navigator.pop(context); // Close drawer
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: colorScheme.onSurfaceVariant,
                        side: BorderSide(color: colorScheme.outline),
                      ),
                      child: Text(l10n.resetButton), // Use localized string
                    ),
                  ),
                  const SizedBox(width: 8), // gap-2
                  Expanded(
                    // Apply Button
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply temporary filters to the provider
                        provider.setCategory(_tempSelectedCategory);
                        if (_tempPriceRange.start > provider.minPrice ||
                            _tempPriceRange.end < provider.maxPrice) {
                          provider.setPriceRange(_tempPriceRange);
                        } else {
                          provider.setPriceRange(null);
                        }
                        Navigator.pop(context); // Close drawer
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: Text(
                        l10n.applyFiltersButton,
                      ), // Use localized string
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to check if state variables are initialized
  bool get isStateInitialized {
    try {
      // Accessing the variables will throw if not initialized
      _tempSelectedCategory;
      _tempPriceRange;
      return true;
    } catch (_) {
      return false;
    }
  }
}
