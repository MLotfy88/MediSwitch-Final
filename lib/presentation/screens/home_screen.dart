import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart';
import '../bloc/medicine_provider.dart';
import 'search_screen.dart';
import 'drug_details_screen.dart';
import '../widgets/drug_card.dart';
import '../widgets/section_header.dart';
import '../widgets/home_header.dart';
import '../widgets/horizontal_list_section.dart';
import '../widgets/category_card.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/search_bar_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../services/ad_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_constants.dart'; // Import constants

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdService _adService = locator<AdService>();
  final FileLoggerService _logger = locator<FileLoggerService>();
  final ScrollController _scrollController =
      ScrollController(); // Re-add ScrollController

  // REMOVED: Maps are now defined in app_constants.dart

  @override
  void initState() {
    super.initState();
    _logger.i("HomeScreen: initState called.");
    _scrollController.addListener(_onScroll); // Re-add listener

    // Trigger initial data load after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if the widget is still in the tree
        _logger.i("HomeScreen: Triggering initial data load from initState.");
        context.read<MedicineProvider>().loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _logger.i("HomeScreen: dispose called.");
    _scrollController.removeListener(_onScroll); // Re-add listener removal
    _scrollController.dispose(); // Re-add dispose
    super.dispose();
  }

  // Re-add _onScroll method for pagination
  void _onScroll() {
    final provider = context.read<MedicineProvider>();
    final currentPixels = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final triggerPoint = maxScroll - 300;
    final bool isNearBottom = currentPixels >= triggerPoint;
    final bool canLoadMore = provider.hasMoreItems && !provider.isLoadingMore && !provider.isLoading;
    final shouldLoadMore = isNearBottom && canLoadMore;

    // Detailed Logging for Pagination (Phase 2, Step 4)
    _logger.v(
      "HomeScreen _onScroll: Pixels=${currentPixels.toStringAsFixed(1)}, MaxScroll=${maxScroll.toStringAsFixed(1)}, TriggerAt=${triggerPoint.toStringAsFixed(1)}, IsNearBottom=$isNearBottom, CanLoadMore=$canLoadMore (HasMore=${provider.hasMoreItems}, !IsLoadingMore=${!provider.isLoadingMore}, !IsLoading=${!provider.isLoading}), ShouldLoad=$shouldLoadMore",
    );

    if (shouldLoadMore) {
      _logger.i("HomeScreen: Reached near bottom, calling loadMoreDrugs...");
      try {
        provider.loadMoreDrugs();
      } catch (e, s) {
        _logger.e("HomeScreen: Error calling loadMoreDrugs", e, s);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("HomeScreen: Building widget...");
    final medicineProvider = context.watch<MedicineProvider>();
    // final isSeeding = medicineProvider.isSeedingDatabase; // REMOVED: Seeding state handled externally
    final isLoading = medicineProvider.isLoading;
    final isLoadingMore =
        medicineProvider.isLoadingMore; // Re-add isLoadingMore
    final error = medicineProvider.error;
    final displayedMedicines = medicineProvider.filteredMedicines;
    // Log state without seeding
    _logger.d(
      "HomeScreen: State - isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: '$error', displayedMedicines: ${displayedMedicines.length}, hasMore: ${medicineProvider.hasMoreItems}",
    );

    return Scaffold(
      // Wrap the body content with SafeArea
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () {
                  _logger.i("HomeScreen: RefreshIndicator triggered.");
                  // Reload all data, including the full list for local filtering
                  return context.read<MedicineProvider>().loadInitialData(
                    forceUpdate: true,
                  );
                },
                // Refined Loading/Error Logic (Phase 1, Step 3)
                child: isLoading && displayedMedicines.isEmpty
                    ? _buildLoadingIndicator() // Initial load indicator
                    : error.isNotEmpty
                        ? _buildErrorWidget(context, error) // Show error prominently
                        : _buildContent( // Build content if not initial loading and no error
                            context,
                            medicineProvider,
                            displayedMedicines,
                            isLoading, // Pass isLoading for internal use (e.g., refresh indicator)
                            isLoadingMore,
                            error, // Pass error for potential footer display
                          ),
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    _logger.v("HomeScreen: Building loading indicator.");
    return const Center(child: CircularProgressIndicator());
  }

  // REMOVED: _buildSeedingIndicator widget is no longer needed.
  // Widget _buildSeedingIndicator() { ... }

  // Re-add isLoadingMore parameter
  Widget _buildContent(
    BuildContext context,
    MedicineProvider medicineProvider,
    List<DrugEntity> displayedMedicines,
    bool isLoading,
    bool isLoadingMore,
    String error,
  ) {
    _logger.v("HomeScreen: Building main content CustomScrollView.");

    return CustomScrollView(
      controller: _scrollController, // Re-add controller
      slivers: [
        SliverToBoxAdapter(child: const SearchBarButton()),
        // --- Categories Section ---
        // Only build categories if initial load is complete
        if (medicineProvider.isInitialLoadComplete)
          SliverToBoxAdapter(child: _buildCategoriesSection(context)),

        // --- Recently Updated Section ---
        // Only build if initial load is complete AND list is not empty
        if (medicineProvider.isInitialLoadComplete &&
            medicineProvider.recentlyUpdatedDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildHorizontalDrugList(
              context,
              title: "أدوية محدثة مؤخراً",
              drugs: medicineProvider.recentlyUpdatedDrugs,
              onViewAll: () {
                _logger.i("HomeScreen: View All Recent tapped.");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchScreen(initialQuery: ''),
                  ),
                );
              },
            ),
          ),

        // --- Popular Drugs Section ---
        // Only build if initial load is complete AND list is not empty
        if (medicineProvider.isInitialLoadComplete &&
            medicineProvider.popularDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildHorizontalDrugList(
              context,
              title: "الأكثر بحثاً", // Translates to "Most Searched" / "Common"
              drugs: medicineProvider.popularDrugs,
              isPopular: true, // Mark these drugs as popular
              onViewAll: () {
                _logger.i("HomeScreen: View All Popular tapped.");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchScreen(initialQuery: ''),
                  ),
                );
              },
            ),
          ),
        // --- END Re-enabled Sections ---

        // --- All Drugs Section Header ---
        SliverToBoxAdapter(
          child: Padding(
            // Apply standard horizontal padding and specific bottom margin (mb-4 -> bottom: 16.0)
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 24.0, // Keep existing top padding
              bottom: 16.0, // Add bottom padding (mb-4)
            ),
            child: SectionHeader(
              title: 'جميع الأدوية',
              padding:
                  EdgeInsets.zero, // Remove default padding from SectionHeader
            ),
          ),
        ),

        // --- All Drugs List ---
        if (displayedMedicines.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final drug = displayedMedicines[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: DrugCard(
                    // Uses kCategoryTranslation internally now
                    drug: drug,
                    type: DrugCardType.detailed,
                    onTap: () => _navigateToDetails(context, drug),
                    // isPopular: drug.isPopular, // Assuming DrugEntity has isPopular flag
                    // isAlternative: drug.isAlternative, // Assuming DrugEntity has isAlternative flag
                  ),
                ).animate().fadeIn(delay: (index % 10 * 50).ms);
              }, childCount: displayedMedicines.length),
            ),
          )
        // Show empty/error state only if not loading more
        else if (!isLoadingMore)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildListFooter(
              context,
              medicineProvider,
              displayedMedicines,
              isLoading,
              isLoadingMore,
              error,
            ), // Pass isLoadingMore
          ),

        // --- Loading More Indicator / End Message ---
        // Show footer if the list is not empty (it contains either loading or end message)
        if (displayedMedicines.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildListFooter(
              context,
              medicineProvider,
              displayedMedicines,
              isLoading,
              isLoadingMore,
              error,
            ), // Pass isLoadingMore
          ),
      ],
    );
  }

  // Helper for building horizontal drug lists
  Widget _buildHorizontalDrugList(
    BuildContext context, {
    required String title,
    required List<DrugEntity> drugs,
    VoidCallback? onViewAll,
    bool isPopular = false, // Add isPopular flag
  }) {
    return HorizontalListSection(
      title: title,
      // listHeight: 190, // Removed fixed height
      onViewAll: onViewAll,
      // headerPadding removed, handled internally
      listPadding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      children:
          drugs
              .map(
                (drug) => DrugCard(
                  // Uses kCategoryTranslation internally now
                  drug: drug,
                  type: DrugCardType.thumbnail,
                  isPopular: isPopular, // Pass the flag here
                  onTap: () => _navigateToDetails(context, drug),
                ).animate().fadeIn(delay: (drugs.indexOf(drug) * 80).ms),
              )
              .toList(),
    );
  }

  // Re-add isLoadingMore parameter
  Widget _buildListFooter(
    BuildContext context,
    MedicineProvider provider,
    List<DrugEntity> medicines,
    bool isLoading,
    bool isLoadingMore,
    String error,
  ) {
    if (isLoadingMore) {
      _logger.v("HomeScreen: Building loading more indicator at end of list.");
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (!provider.hasMoreItems && medicines.isNotEmpty) {
      // Re-add hasMoreItems check
      _logger.v("HomeScreen: Building 'end of list' message.");
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Center(
          child: Text(
            'وصلت إلى نهاية القائمة',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
        ),
      );
    } else if (medicines.isEmpty && !isLoading && error.isNotEmpty) {
      return _buildErrorWidget(context, error);
    } else if (medicines.isEmpty && !isLoading && error.isEmpty) {
      return _buildEmptyListMessage(context, provider);
    } else {
      return const SizedBox(height: 16); // Default bottom padding
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    return const SearchBarButton();
  }

  Widget _buildCategoriesSection(BuildContext context) {
    // Use maps directly from imported constants (kCategoryTranslation, kCategoryIcons)

    // These are the keys fetched from the provider (e.g., 'pain_management', 'vitamins')
    final englishCategories = context.watch<MedicineProvider>().categories;

    _logger.v(
      "HomeScreen: Building categories section. Found ${englishCategories.length} categories from provider: $englishCategories",
    );

    if (englishCategories.isEmpty &&
        context.watch<MedicineProvider>().isLoading) {
      return const SizedBox(
        height: 115,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (englishCategories.isEmpty) {
      _logger.w("HomeScreen: No categories found to display.");
      return const SizedBox.shrink();
    }

    // Filter out categories that don't have a translation defined
    final displayableCategories =
        englishCategories
            .where(
              (key) =>
                  kCategoryTranslation.containsKey(key), // Use constant map
            )
            .toList();

    _logger.v(
      "HomeScreen: Displayable categories after filtering: ${displayableCategories.length}",
    );

    return HorizontalListSection(
      title: 'الفئات الطبية',
      listHeight: 105,
      // headerPadding removed
      listPadding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      children:
          // Iterate through the ORIGINAL English categories (keys from CSV)
          displayableCategories.map((englishCategoryName) {
            // 1. Translate to Arabic using the updated map
            final arabicCategoryName =
                kCategoryTranslation[englishCategoryName] ?? // Use constant map
                englishCategoryName; // Fallback

            // 2. Look up icon using the ORIGINAL English key (from CSV)
            final iconData =
                kCategoryIcons[englishCategoryName] ?? // Use constant map
                kCategoryIcons['default']!;

            // 3. Build the card
            return CategoryCard(
                  key: ValueKey(
                    englishCategoryName,
                  ), // Use English name for stable key
                  name:
                      arabicCategoryName, // Display the translated (or original) name
                  iconData: iconData, // Use the looked-up icon
                  onTap: () {
                    _logger.i(
                      "HomeScreen: Category tapped: $arabicCategoryName (English: $englishCategoryName)",
                    );
                    _adService.incrementUsageCounterAndShowAdIfNeeded();
                    // Use the original English name when setting the filter
                    context.read<MedicineProvider>().setCategory(
                      englishCategoryName,
                    );
                  },
                )
                .animate()
                .scale(
                  delay:
                      (displayableCategories.indexOf(englishCategoryName) * 100)
                          .ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(
                  delay:
                      (displayableCategories.indexOf(englishCategoryName) * 100)
                          .ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                );
          }).toList(),
    );
  }

  void _navigateToDetails(BuildContext context, DrugEntity drug) {
    _logger.i("HomeScreen: Navigating to details for drug: ${drug.tradeName}");
    _adService.incrementUsageCounterAndShowAdIfNeeded();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrugDetailsScreen(drug: drug)),
    );
  }

  Widget _buildEmptyListMessage(
    BuildContext context,
    MedicineProvider provider,
  ) {
    // Check selectedCategory (single string)
    final bool filtersActive =
        provider.searchQuery.isNotEmpty || provider.selectedCategory.isNotEmpty;
    _logger.v(
      "HomeScreen: Building empty list message. Filters active: $filtersActive",
    );
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 64,
            color: Theme.of(context).hintColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            filtersActive
                ? 'لا توجد نتائج تطابق الفلاتر الحالية.'
                : 'لا توجد أدوية لعرضها حالياً.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          if (!filtersActive)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'حاول سحب الشاشة للأسفل للتحديث.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    _logger.w("HomeScreen: Building error widget: $error");
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: Theme.of(context).colorScheme.error,
            size: 64.0,
          ),
          const SizedBox(height: 16.0),
          Text(
            'حدث خطأ',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            error,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error.withOpacity(0.8),
              fontSize: 16.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          ElevatedButton.icon(
            icon: Icon(LucideIcons.refreshCw),
            label: const Text('إعادة المحاولة'),
            onPressed: () {
              _logger.i("HomeScreen: Retry button pressed.");
              context.read<MedicineProvider>().loadInitialData(
                forceUpdate: true,
              );
            },
          ),
        ],
      ),
    );
  }
}
