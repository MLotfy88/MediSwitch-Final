import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';

class FilterState {
  final RangeValues priceRange;
  final String sortBy;
  final List<String> forms;
  final List<String> companies;

  const FilterState({
    this.priceRange = const RangeValues(0, 500),
    this.sortBy = 'relevance',
    this.forms = const [],
    this.companies = const [],
  });

  FilterState copyWith({
    RangeValues? priceRange,
    String? sortBy,
    List<String>? forms,
    List<String>? companies,
  }) {
    return FilterState(
      priceRange: priceRange ?? this.priceRange,
      sortBy: sortBy ?? this.sortBy,
      forms: forms ?? this.forms,
      companies: companies ?? this.companies,
    );
  }
}

class SearchFiltersSheet extends StatefulWidget {
  final FilterState filters;
  final ValueChanged<FilterState> onApplyFilters;
  final bool isRTL;

  const SearchFiltersSheet({
    super.key,
    this.filters = const FilterState(),
    required this.onApplyFilters,
    this.isRTL = false,
  });

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  late RangeValues _priceRange;
  late String _sortBy;
  late List<String> _selectedForms;
  late List<String> _selectedCompanies;

  // Data from design docs
  final List<Map<String, String>> _sortOptions = [
    {'id': 'relevance', 'label': 'Relevance'},
    {'id': 'price-low', 'label': 'Price: Low to High'},
    {'id': 'price-high', 'label': 'Price: High to Low'},
    {'id': 'name-az', 'label': 'Name: A-Z'},
    {'id': 'newest', 'label': 'Newest First'},
  ];

  final List<Map<String, String>> _forms = [
    {'id': 'tablet', 'label': 'Tablets'},
    {'id': 'capsule', 'label': 'Capsules'},
    {'id': 'syrup', 'label': 'Syrups'},
    {'id': 'injection', 'label': 'Injections'},
    {'id': 'cream', 'label': 'Creams'},
    {'id': 'drops', 'label': 'Drops'},
  ];

  final List<String> _companies = [
    'GSK',
    'Novartis',
    'Pfizer',
    'Sanofi',
    'AstraZeneca',
    'Bayer',
    'EVA Pharma',
    'Amoun',
  ];

  @override
  void initState() {
    super.initState();
    _priceRange = widget.filters.priceRange;
    _sortBy = widget.filters.sortBy;
    _selectedForms = List.from(widget.filters.forms);
    _selectedCompanies = List.from(widget.filters.companies);
  }

  void _resetFilters() {
    setState(() {
      _priceRange = const RangeValues(0, 500);
      _sortBy = 'relevance';
      _selectedForms = [];
      _selectedCompanies = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
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
                  onPressed: _resetFilters,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(6),
                    backgroundColor: Colors.transparent,
                    hoverColor: appColors.accent,
                    foregroundColor: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range Section
                  _buildSectionTitle(theme, 'Price Range (EGP)'),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 1000,
                      activeColor: theme.colorScheme.primary,
                      inactiveColor: theme.colorScheme.secondary.withValues(
                        alpha: 0.3,
                      ), // Approx bg-secondary soft
                      onChanged: (values) {
                        setState(() {
                          _priceRange = values;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_priceRange.start.round()} EGP',
                          style: TextStyle(
                            fontSize: 14,
                            color: appColors.mutedForeground,
                          ),
                        ),
                        Text(
                          '${_priceRange.end.round()} EGP',
                          style: TextStyle(
                            fontSize: 14,
                            color: appColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sort By Section
                  _buildSectionTitle(theme, 'Sort By'),
                  const SizedBox(height: 8),
                  ..._sortOptions.map(
                    (option) => _buildSortOption(
                      theme,
                      appColors,
                      option['label']!,
                      option['id']!,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Drug Form Section
                  _buildSectionTitle(theme, 'Drug Form'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _forms
                            .map(
                              (form) => _buildChip(
                                theme,
                                appColors,
                                form['label']!,
                                form['id']!,
                                _selectedForms,
                                isSecondary: false,
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Company Section
                  _buildSectionTitle(theme, 'Company'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _companies
                            .map(
                              (company) => _buildChip(
                                theme,
                                appColors,
                                company,
                                company,
                                _selectedCompanies,
                                isSecondary: true,
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Footer
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(
                    FilterState(
                      priceRange: _priceRange,
                      sortBy: _sortBy,
                      forms: _selectedForms,
                      companies: _selectedCompanies,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18), // rounded-xl
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSortOption(
    ThemeData theme,
    AppColorsExtension appColors,
    String label,
    String id,
  ) {
    final isSelected = _sortBy == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _sortBy = id;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : appColors.accent,
            borderRadius: BorderRadius.circular(18), // rounded-xl
            border:
                isSelected
                    ? Border.all(color: theme.colorScheme.primary)
                    : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:
                      isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                ),
              ),
              if (isSelected)
                Icon(
                  LucideIcons.check,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    ThemeData theme,
    AppColorsExtension appColors,
    String label,
    String id,
    List<String> selectionList, {
    required bool isSecondary,
  }) {
    final isSelected = selectionList.contains(id);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectionList.remove(id);
          } else {
            selectionList.add(id);
          }
        });
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isSecondary
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary)
                  : appColors.accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color:
                isSelected
                    ? (isSecondary
                        ? theme.colorScheme.onSecondary
                        : theme.colorScheme.onPrimary)
                    : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
