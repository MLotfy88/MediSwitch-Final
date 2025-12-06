import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/design_tokens.dart';

class FilterState {
  final RangeValues priceRange;
  final List<String> companies;
  final List<String> forms;
  final String sortBy;

  const FilterState({
    this.priceRange = const RangeValues(0, 500),
    this.companies = const [],
    this.forms = const [],
    this.sortBy = 'relevance',
  });

  FilterState copyWith({
    RangeValues? priceRange,
    List<String>? companies,
    List<String>? forms,
    String? sortBy,
  }) {
    return FilterState(
      priceRange: priceRange ?? this.priceRange,
      companies: companies ?? this.companies,
      forms: forms ?? this.forms,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class SearchFiltersSheet extends StatefulWidget {
  final FilterState filters;
  final Function(FilterState) onApplyFilters;
  final bool isRTL;

  const SearchFiltersSheet({
    super.key,
    required this.filters,
    required this.onApplyFilters,
    this.isRTL = false,
  });

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late FilterState _localFilters;

  final companies = [
    'GSK',
    'Novartis',
    'Pfizer',
    'Sanofi',
    'AstraZeneca',
    'Bayer',
    'EVA Pharma',
    'Amoun',
  ];

  final forms = [
    {'id': 'tablet', 'label': 'Tablets'},
    {'id': 'capsule', 'label': 'Capsules'},
    {'id': 'syrup', 'label': 'Syrups'},
    {'id': 'injection', 'label': 'Injections'},
    {'id': 'cream', 'label': 'Creams'},
    {'id': 'drops', 'label': 'Drops'},
  ];

  final sortOptions = [
    {'id': 'relevance', 'label': 'Relevance'},
    {'id': 'price-low', 'label': 'Price: Low to High'},
    {'id': 'price-high', 'label': 'Price: High to Low'},
    {'id': 'name-az', 'label': 'Name: A-Z'},
    {'id': 'newest', 'label': 'Newest First'},
  ];

  @override
  void initState() {
    super.initState();
    _localFilters = widget.filters;
  }

  void _toggleCompany(String company) {
    setState(() {
      final newCompanies = List<String>.from(_localFilters.companies);
      if (newCompanies.contains(company)) {
        newCompanies.remove(company);
      } else {
        newCompanies.add(company);
      }
      _localFilters = _localFilters.copyWith(companies: newCompanies);
    });
  }

  void _toggleForm(String form) {
    setState(() {
      final newForms = List<String>.from(_localFilters.forms);
      if (newForms.contains(form)) {
        newForms.remove(form);
      } else {
        newForms.add(form);
      }
      _localFilters = _localFilters.copyWith(forms: newForms);
    });
  }

  void _handleReset() {
    setState(() {
      _localFilters = const FilterState();
    });
  }

  void _handleApply() {
    widget.onApplyFilters(_localFilters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _handleReset,
                  child: Text(
                    widget.isRTL ? 'إعادة تعيين' : 'Reset',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  widget.isRTL ? 'فلاتر' : 'Filters',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range
                  Text(
                    widget.isRTL ? 'نطاق السعر (ج.م)' : 'Price Range (EGP)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        RangeSlider(
                          values: _localFilters.priceRange,
                          min: 0,
                          max: 500,
                          divisions: 50,
                          onChanged: (values) {
                            setState(() {
                              _localFilters = _localFilters.copyWith(
                                priceRange: values,
                              );
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_localFilters.priceRange.start.round()} EGP',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${_localFilters.priceRange.end.round()} EGP',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sort By
                  Text(
                    widget.isRTL ? 'ترتيب حسب' : 'Sort By',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...sortOptions.map((option) {
                    final isSelected = _localFilters.sortBy == option['id'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _localFilters = _localFilters.copyWith(
                              sortBy: option['id'] as String,
                            );
                          });
                        },
                        borderRadius: AppRadius.circular,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest,
                            borderRadius: AppRadius.circular,
                            border: Border.all(
                              color:
                                  isSelected
                                      ? colorScheme.primary
                                      : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                option['label'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurface,
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  LucideIcons.check,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Drug Form
                  Text(
                    widget.isRTL ? 'شكل الدواء' : 'Drug Form',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        forms.map((form) {
                          final isSelected = _localFilters.forms.contains(
                            form['id'],
                          );
                          return FilterChip(
                            label: Text(form['label'] as String),
                            selected: isSelected,
                            onSelected:
                                (_) => _toggleForm(form['id'] as String),
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            selectedColor: colorScheme.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Company
                  Text(
                    widget.isRTL ? 'الشركة' : 'Company',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        companies.map((company) {
                          final isSelected = _localFilters.companies.contains(
                            company,
                          );
                          return FilterChip(
                            label: Text(company),
                            selected: isSelected,
                            onSelected: (_) => _toggleCompany(company),
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            selectedColor: colorScheme.secondary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList(),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _handleApply,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.circular,
                    ),
                  ),
                  child: Text(
                    widget.isRTL ? 'تطبيق الفلاتر' : 'Apply Filters',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
