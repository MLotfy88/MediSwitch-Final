import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../domain/entities/drug_entity.dart';
import '../../presentation/theme/app_colors.dart';
import '../bloc/medicine_provider.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/cards/modern_drug_card.dart';
import '../widgets/filter_pills.dart';
import '../widgets/modern_search_bar.dart';
import '../widgets/search_filters_sheet.dart';
import 'drug_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  final String? initialCategory;
  const SearchScreen({super.key, this.initialQuery = '', this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FileLoggerService _logger = locator<FileLoggerService>();
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
        if (widget.initialQuery.isNotEmpty &&
            provider.searchQuery != widget.initialQuery) {
          provider.setSearchQuery(widget.initialQuery); // Trigger search
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
    if (currentScroll >= (maxScroll - 200) &&
        provider.hasMoreItems &&
        !provider.isLoadingMore) {
      provider.loadMoreDrugs();
    }
  }

  void _openFilters() {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    showModalBottomSheet(
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
      MaterialPageRoute(
        builder: (context) => DrugDetailsScreen(drug: drug),
      ), // Fix: use drugId
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<MedicineProvider>();
    // final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.arrowLeft,
                        size: 20,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernSearchBar(
                      controller: _searchController,
                      hintText: l10n.searchHint,
                      onChanged: (query) {
                        provider.setSearchQuery(
                          query,
                          triggerSearch: true,
                        ); // Debouncing usually handled in provider or here
                      },
                      onFilterTap: _openFilters,
                    ),
                  ),
                ],
              ),
            ),

            // Filter Pills
            Container(
              color: AppColors.surface,
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

            // Results List
            Expanded(child: _buildResultsList(context, provider, l10n)),
            const BannerAdWidget(placement: BannerAdPlacement.searchBottom),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(
    BuildContext context,
    MedicineProvider provider,
    AppLocalizations l10n,
  ) {
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
            const Icon(
              LucideIcons.search,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noResultsFoundTitle,
              style: const TextStyle(color: AppColors.mutedForeground),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ModernDrugCard(
            drug: drug,
            hasInteraction: false, // Calculate if needed
            onTap: () => _navigateToDetails(context, drug),
          ),
        );
      },
    );
  }
}
