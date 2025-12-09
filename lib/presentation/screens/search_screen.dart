import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/screens/details/drug_details_screen.dart';
import 'package:mediswitch/presentation/services/ad_service.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/widgets/banner_ad_widget.dart';
import 'package:mediswitch/presentation/widgets/cards/modern_drug_card.dart';
import 'package:mediswitch/presentation/widgets/filter_pills.dart';
import 'package:mediswitch/presentation/widgets/modern_search_bar.dart';
import 'package:mediswitch/presentation/widgets/search_filters_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة البحث عن الأدوية مع دعم Infinite scroll والفلاتر
class SearchScreen extends StatefulWidget {
  /// الاستعلام الأولي للبحث
  final String initialQuery;

  /// الفئة الأولية للفلترة
  final String? initialCategory;

  /// إنشاء شاشة بحث جديدة
  const SearchScreen({super.key, this.initialQuery = '', this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AdService _adService = locator<AdService>();
  final ScrollController _scrollController = ScrollController();

  String _selectedDosageForm = 'All'; // Local state for filter pill
  FilterState _currentFilters = const FilterState(); // Added filter state

  List<String> _searchHistory = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchController.text = widget.initialQuery;

    // Initial setup listeners ...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MedicineProvider>();

        // Handle Initial Query
        if (widget.initialQuery.isNotEmpty &&
            provider.searchQuery != widget.initialQuery) {
          provider.setSearchQuery(widget.initialQuery);
          _addToHistory(widget.initialQuery);
        }
        // Handle Initial Category
        else if (widget.initialCategory != null &&
            widget.initialCategory!.isNotEmpty) {
          provider.setCategory(widget.initialCategory!);
          // Don't add category to text history usually, or maybe we do?
          // Usually history is typed text.
        }
      }
    });

    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
      _isHistoryLoading = false;
    });
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('search_history') ?? [];

    // Remove if exists to move to top
    history.remove(query.trim());
    // Add to start
    history.insert(0, query.trim());
    // Limit to 10
    if (history.length > 10) {
      history = history.sublist(0, 10);
    }

    await prefs.setStringList('search_history', history);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('search_history') ?? [];
    history.remove(query);
    await prefs.setStringList('search_history', history);
    if (mounted) {
      setState(() {
        _searchHistory = history;
      });
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    if (mounted) {
      setState(() {
        _searchHistory = [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<MedicineProvider>();
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= (maxScroll - 200) &&
        provider.hasMoreItems &&
        !provider.isLoadingMore) {
      provider.loadMoreDrugs();
    }
  }

  void _openFilters() {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => SearchFiltersSheet(
            filters: _currentFilters,
            onApplyFilters: (newFilters) {
              setState(() => _currentFilters = newFilters);
            },
            isRTL: isRTL,
          ),
    );
  }

  void _navigateToDetails(BuildContext context, DrugEntity drug) {
    _adService.incrementUsageCounterAndShowAdIfNeeded();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => DrugDetailsScreen(drug: drug),
      ),
    );
  }

  // Calculate generic "active filters" count manually
  int get _activeFiltersCount {
    int count = 0;
    // Price range - check if changed from default
    if (_currentFilters.priceRange.start > 0 ||
        _currentFilters.priceRange.end < 500) {
      count++;
    }
    // Forms
    if (_currentFilters.forms.isNotEmpty) count++;
    // Companies
    if (_currentFilters.companies.isNotEmpty) count++;
    // Sort
    if (_currentFilters.sortBy != 'relevance') count++;
    // Dosage form
    if (_selectedDosageForm != 'All') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<MedicineProvider>();
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // ✅ استخدام theme colors
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // ✅ استخدام theme background
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: colorScheme.surface,
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isRTL
                              ? LucideIcons.arrowRight
                              : LucideIcons.arrowLeft,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernSearchBar(
                      controller: _searchController,
                      hintText: l10n.searchHint,
                      onChanged: (String query) {
                        provider.setSearchQuery(query, triggerSearch: true);
                        if (query.isNotEmpty) {
                          _addToHistory(query);
                        }
                      },
                      onFilterTap: _openFilters,
                    ),
                  ),
                ],
              ),
            ),

            // Filter Pills
            Container(
              color: colorScheme.surface,
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 12),
              child: FilterPills(
                selectedFilter: _selectedDosageForm,
                onFilterSelected: (val) {
                  setState(() => _selectedDosageForm = val);
                  provider.setDosageForm(
                    val == 'All' ? '' : val,
                  ); // Update provider
                },
              ),
            ),

            // Results Count & Active Filters Header
            if (!provider.isLoading && provider.filteredMedicines.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Count
                    Row(
                      children: [
                        Text(
                          '${provider.filteredMedicines.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isRTL ? "نتائج" : "results",
                          style: TextStyle(
                            fontSize: 14,
                            color: appColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),

                    // Active Filters Badge
                    if (_activeFiltersCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isRTL
                              ? '$_activeFiltersCount فلاتر نشطة'
                              : '$_activeFiltersCount active filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Main Content: History OR Results
            Expanded(
              child:
                  (provider.searchQuery.isEmpty &&
                          provider.selectedCategory.isEmpty)
                      ? _buildHistoryList(context, isRTL)
                      : _buildResultsList(context, provider, l10n),
            ),
            const BannerAdWidget(placement: BannerAdPlacement.searchBottom),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);
    if (_isHistoryLoading) return const SizedBox.shrink();

    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.history,
              size: 48,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              isRTL ? 'إبحث عن الأدوية' : 'Search for medicines',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRTL ? 'بحث سابق' : 'Recent Searches',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: _clearHistory,
                child: Text(
                  isRTL ? 'مسح الكل' : 'Clear All',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(LucideIcons.clock, size: 16),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () => _removeFromHistory(query),
                ),
                onTap: () {
                  _searchController.text = query;
                  context.read<MedicineProvider>().setSearchQuery(query);
                  _addToHistory(query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    MedicineProvider provider,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final colorScheme = theme.colorScheme;

    if (provider.isLoading && provider.filteredMedicines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.filteredMedicines.isEmpty) {
      if (provider.error.isNotEmpty) {
        return Center(child: Text(provider.error)); // Simple error
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.searchX,
                size: 40,
                color: appColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noResultsFoundTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "حاول تعديل البحث أو الفلاتر",
              style: TextStyle(fontSize: 14, color: appColors.mutedForeground),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          provider.filteredMedicines.length + (provider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= provider.filteredMedicines.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final drug = provider.filteredMedicines[index];
        // Add Animation
        return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ModernDrugCard(
                drug: drug,
                hasInteraction: false, // Calculate if needed
                onTap: () => _navigateToDetails(context, drug),
              ),
            )
            .animate()
            .fadeIn(duration: 300.ms, delay: (50 * index).ms)
            .slideY(begin: 0.1, end: 0);
      },
    );
  }
}
