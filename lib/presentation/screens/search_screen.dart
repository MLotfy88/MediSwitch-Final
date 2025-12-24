import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;

    // Initial setup listeners ...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MedicineProvider>();

        // Handle Initial Query
        if (widget.initialQuery.isNotEmpty &&
            provider.searchQuery != widget.initialQuery) {
          provider.setSearchQuery(widget.initialQuery);
        }
        // Handle Initial Category
        else if (widget.initialCategory != null &&
            widget.initialCategory!.isNotEmpty) {
          provider.setCategory(widget.initialCategory!);
        }
        // Handle Default Case (Entry logic)
        // If coming from Home or Tab, we want to show "All Drugs" (paginated)
        // Since we don't pre-load them anymore, we MUST trigger a search here.
        else {
          // Only trigger if list is empty to avoid re-loading if we navigate back/forth
          // (though SearchScreen seems to be Pushed, so new instance usually)
          if (provider.filteredMedicines.isEmpty &&
              provider.searchQuery.isEmpty) {
            provider.loadInitialSearchDrugs();
          }
        }
      }
    });

    _scrollController.addListener(_onScroll);
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

    // Check if we are near bottom (threshold 100 or 10% of list)
    // If the list is small, maxScroll might be small, so we must be careful.
    final threshold = 100.0;

    if (currentScroll >= (maxScroll - threshold) &&
        provider.hasMoreItems &&
        !provider.isLoadingMore) {
      // Debounce slightly if needed, but provider locks with _isLoadingMore
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
    // Add to Recent History
    context.read<MedicineProvider>().addToRecentlyViewed(drug);

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
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: colorScheme.surface,
              child: ModernSearchBar(
                controller: _searchController,
                hintText: isRTL ? 'ابحث عن دواء...' : l10n.searchHint,
                onChanged: (String query) {
                  provider.setSearchQuery(query, triggerSearch: true);
                },
                onFilterTap: _openFilters,
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
            Expanded(child: _buildResultsList(context, provider, l10n)),
            const BannerAdWidget(placement: BannerAdPlacement.searchBottom),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    MedicineProvider provider,
    bool isRTL,
  ) {
    final theme = Theme.of(context);
    final recentDrugs = provider.recentlyViewedDrugs;

    if (recentDrugs.isEmpty) {
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
              isRTL
                  ? 'لم تقم بزيارة أي أدوية مؤخراً'
                  : 'No recently viewed drugs',
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
          child: Text(
            isRTL ? 'الأدوية التي تم زيارتها مؤخراً' : 'Recently Viewed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recentDrugs.length,
            itemBuilder: (context, index) {
              final drug = recentDrugs[index];
              final displayDrug = drug.copyWith(
                isPopular: provider.isDrugPopular(drug.id),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ModernDrugCard(
                  drug: displayDrug,
                  hasDrugInteraction: drug.hasDrugInteraction,
                  hasFoodInteraction: drug.hasFoodInteraction,
                  onTap: () => _navigateToDetails(context, drug),
                ),
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

    // Auto-load more if the list is too short to scroll
    if (provider.hasMoreItems &&
        !provider.isLoadingMore &&
        provider.filteredMedicines.isNotEmpty &&
        provider.filteredMedicines.length <= 8) {
      // Schedule a load after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && provider.hasMoreItems && !provider.isLoadingMore) {
          provider.loadMoreDrugs();
        }
      });
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      physics:
          const AlwaysScrollableScrollPhysics(), // Ensure scrollable even if short
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
        final displayDrug = drug.copyWith(
          isPopular: provider.isDrugPopular(drug.id),
        );
        // Add Animation
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ModernDrugCard(
            drug: displayDrug,
            hasDrugInteraction: drug.hasDrugInteraction,
            hasFoodInteraction: drug.hasFoodInteraction,
            onTap: () => _navigateToDetails(context, drug),
          ),
        );
      },
    );
  }
}
