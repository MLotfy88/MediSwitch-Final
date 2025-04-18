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
  // REMOVED: ScrollController no longer needed here
  // final ScrollController _scrollController = ScrollController();

  // REMOVED: Maps are now defined in app_constants.dart

  @override
  void initState() {
    super.initState();
    _logger.i("HomeScreen: +++++ initState +++++"); // Lifecycle Log
    // REMOVED: Scroll listener no longer needed here
    // _scrollController.addListener(_onScroll);

    // REMOVED: Redundant call to loadInitialData. Provider handles this in constructor.
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (mounted) {
    //     _logger.i("HomeScreen: Triggering initial data load from initState.");
    //     context.read<MedicineProvider>().loadInitialData();
    //   }
    // });
  }

  @override
  void dispose() {
    _logger.i("HomeScreen: ----- dispose -----"); // Lifecycle Log
    // REMOVED: Dispose scroll controller
    // _scrollController.removeListener(_onScroll);
    // _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("HomeScreen: >>>>> build ENTRY <<<<<"); // Updated Log
    try {
      // Add try block here
      final medicineProvider = context.watch<MedicineProvider>();
      final isLoading = medicineProvider.isLoading;
      final isLoadingMore = medicineProvider.isLoadingMore;
      final error = medicineProvider.error; // Still needed for error display
      // final displayedMedicines = medicineProvider.filteredMedicines; // No longer needed here
      final isInitialLoadComplete =
          medicineProvider.isInitialLoadComplete; // Get this state
      final recentlyUpdatedCount = medicineProvider.recentlyUpdatedDrugs.length;
      final popularCount = medicineProvider.popularDrugs.length;

      // Log state at build time
      _logger.d(
        "HomeScreen BUILD State: isLoading=$isLoading, isLoadingMore=$isLoadingMore, isInitialLoadComplete=$isInitialLoadComplete, error='$error', recent=$recentlyUpdatedCount, popular=$popularCount", // Removed displayed/hasMore
      );

      // Log before returning Scaffold
      _logger.v(
        "HomeScreen: build - State read successfully. Returning Scaffold...",
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
                  child:
                      isLoading && !isInitialLoadComplete
                          ? _buildLoadingIndicator() // Initial load indicator
                          : error.isNotEmpty
                          ? _buildErrorWidget(
                            context,
                            error,
                          ) // Show error prominently
                          : (isInitialLoadComplete ||
                              recentlyUpdatedCount > 0 ||
                              popularCount > 0)
                          ? _buildContent(
                            // Correctly call _buildContent here
                            context,
                            medicineProvider,
                            isLoading,
                            isLoadingMore,
                            error,
                            isInitialLoadComplete,
                            recentlyUpdatedCount,
                            popularCount,
                          )
                          : _buildLoadingIndicator(), // Fallback if not loading/error but no content yet
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      );
    } catch (e, s) {
      // Catch and log any error during the build method
      _logger.e("HomeScreen: >>>>> CRITICAL ERROR DURING BUILD <<<<<", e, s);
      // Return a simple error widget instead of crashing
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error building HomeScreen:\n$e\n\n$s', // Include stack trace
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textDirection: TextDirection.ltr, // Ensure LTR for error messages
            ),
          ),
        ),
      );
    } finally {
      _logger.i("HomeScreen: >>>>> build EXIT <<<<<"); // Log exit
    }
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
    MedicineProvider medicineProvider, // Keep provider for accessing lists
    // List<DrugEntity> displayedMedicines, // No longer needed
    bool isLoading,
    bool isLoadingMore,
    String error,
    // Add parameters for state checks
    bool isInitialLoadComplete,
    int recentlyUpdatedCount,
    int popularCount,
  ) {
    _logger.v("HomeScreen: Building main content CustomScrollView.");
    // Log state *before* rendering sections
    _logger.d(
      "HomeScreen Section Render Check: isInitialLoadComplete=$isInitialLoadComplete, recentCount=$recentlyUpdatedCount, popularCount=$popularCount",
    );

    return CustomScrollView(
      // controller: _scrollController, // REMOVED: No controller needed
      slivers: [
        SliverToBoxAdapter(child: const SearchBarButton()),
        // --- Categories Section ---
        if (isInitialLoadComplete) // Use passed parameter
          SliverToBoxAdapter(child: _buildCategoriesSection(context)),

        // --- Recently Updated Section ---
        if (isInitialLoadComplete &&
            recentlyUpdatedCount > 0) // Use passed parameters
          SliverToBoxAdapter(
            child: _buildHorizontalDrugList(
              context,
              title: "أدوية محدثة مؤخراً",
              drugs:
                  medicineProvider
                      .recentlyUpdatedDrugs, // Get data from provider
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
        if (isInitialLoadComplete && popularCount > 0) // Use passed parameters
          SliverToBoxAdapter(
            child: _buildHorizontalDrugList(
              context,
              title: "الأكثر بحثاً", // Translates to "Most Searched" / "Common"
              drugs: medicineProvider.popularDrugs, // Get data from provider
              isPopular: true,
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

        // --- REMOVED All Drugs Section ---
        // SliverToBoxAdapter(child: SectionHeader(...)),
        // if (displayedMedicines.isNotEmpty) SliverPadding(...)
        // else if (!isLoadingMore) SliverFillRemaining(...)
        // if (displayedMedicines.isNotEmpty) SliverToBoxAdapter(_buildListFooter(...))

        // Add some padding at the bottom if needed
        const SliverPadding(padding: EdgeInsets.only(bottom: 16.0)),
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

  // REMOVED: _buildListFooter is no longer needed in HomeScreen
  // Widget _buildListFooter(...) { ... }

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

    // Helper function to normalize keys (lowercase, replace space/uppercase with underscore)
    String normalizeKey(String key) {
      return key
          .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)}')
          .replaceAll(' ', '_')
          .toLowerCase()
          .replaceAll(RegExp(r'^_+'), '');
    }

    // Filter based on normalized keys having a translation
    final displayableCategories =
        englishCategories
            .where((key) => kCategoryTranslation.containsKey(normalizeKey(key)))
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
            final normalizedKey = normalizeKey(englishCategoryName);
            final arabicCategoryName =
                kCategoryTranslation[normalizedKey] ?? // Use normalized key for lookup
                englishCategoryName; // Fallback

            // 2. Look up icon using the ORIGINAL English key (from CSV)
            final iconData =
                kCategoryIcons[normalizedKey] ?? // Use normalized key for lookup
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

  // REMOVED: _buildEmptyListMessage is no longer needed in HomeScreen
  // Widget _buildEmptyListMessage(...) { ... }

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
