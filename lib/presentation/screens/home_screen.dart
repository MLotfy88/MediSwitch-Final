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
import '../widgets/quick_stats_banner.dart'; // Import Quick Stats Banner
import '../widgets/price_alerts_card.dart'; // Import Price Alerts Card
import '../widgets/high_risk_drugs_card.dart'; // Import High Risk Drugs Card
import '../widgets/skeleton_loader.dart'; // Import Skeleton Loader
import '../widgets/empty_state_widget.dart'; // Import Empty State Widget
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../services/ad_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_constants.dart'; // Import constants
import '../../core/constants/app_spacing.dart'; // Import spacing constants
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdService _adService = locator<AdService>();
  final FileLoggerService _logger = locator<FileLoggerService>();
  // REMOVED: ScrollController no longer needed here

  // REMOVED: Maps are now defined in app_constants.dart

  @override
  void initState() {
    super.initState();
    _logger.i("HomeScreen: +++++ initState +++++"); // Lifecycle Log
    // REMOVED: Scroll listener no longer needed here
    // REMOVED: Redundant call to loadInitialData. Provider handles this in constructor.
  }

  @override
  void dispose() {
    _logger.i("HomeScreen: ----- dispose -----"); // Lifecycle Log
    // REMOVED: Dispose scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("HomeScreen: >>>>> build ENTRY <<<<<"); // Updated Log
    try {
      // Add try block here
      final l10n = AppLocalizations.of(context)!; // Get localizations instance
      final medicineProvider = context.watch<MedicineProvider>();
      final isLoading = medicineProvider.isLoading;
      final isLoadingMore = medicineProvider.isLoadingMore;
      final error = medicineProvider.error; // Still needed for error display
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
          // Add overall padding if desired, or handle within CustomScrollView
          // padding: AppSpacing.edgeInsetsAllMedium,
          child: Column(
            children: [
              const HomeHeader(
                notificationCount: 3,
              ), // TODO: Get actual count from notification service
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    _logger.i("HomeScreen: RefreshIndicator triggered.");
                    // Reload all data, including the full list for local filtering
                    return context.read<MedicineProvider>().loadInitialData(
                      forceUpdate: true,
                    );
                  },
                  // Refined Loading/Error Logic
                  child:
                      isLoading && !isInitialLoadComplete
                          ? _buildLoadingIndicator() // Initial load indicator
                          : error.isNotEmpty
                          ? _buildErrorWidget(
                            context,
                            error,
                            l10n, // Pass l10n
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
                            l10n, // Pass l10n
                          )
                          : _buildLoadingIndicator(), // Fallback if not loading/error but no content yet
                ),
              ),
              const BannerAdWidget(), // Ad widget at the bottom
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
            padding: AppSpacing.edgeInsetsAllLarge, // Use constant
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

  // Re-add isLoadingMore parameter
  Widget _buildContent(
    BuildContext context,
    MedicineProvider medicineProvider, // Keep provider for accessing lists
    bool isLoading,
    bool isLoadingMore,
    String error,
    // Add parameters for state checks
    bool isInitialLoadComplete,
    int recentlyUpdatedCount,
    int popularCount,
    AppLocalizations l10n,
  ) {
    _logger.v("HomeScreen: Building main content.");
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Top spacing
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Search Bar - Integrated design
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: const SearchBarButton()),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Quick Stats Banner
        SliverToBoxAdapter(
          child:
              !isInitialLoadComplete
                  ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SkeletonCard(height: 100),
                  )
                  : QuickStatsBanner(
                    totalDrugs: medicineProvider.filteredMedicines.length,
                    todayUpdates: medicineProvider.recentlyUpdatedDrugs.length,
                    priceIncreases: _countPriceChanges(
                      medicineProvider.recentlyUpdatedDrugs,
                      true,
                    ),
                    priceDecreases: _countPriceChanges(
                      medicineProvider.recentlyUpdatedDrugs,
                      false,
                    ),
                  ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Price Alerts Card - Top price changes
        if (!isInitialLoadComplete)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SkeletonCard(height: 180),
            ),
          )
        else if (medicineProvider.recentlyUpdatedDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: PriceAlertsCard(
              topChangedDrugs: _getTopChangedDrugs(
                medicineProvider.recentlyUpdatedDrugs,
                3,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // High Risk Drugs Section
        if (!isInitialLoadComplete)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SkeletonCard(height: 180),
            ),
          )
        else
          SliverToBoxAdapter(
            child: HighRiskDrugsCard(
              allDrugs: medicineProvider.filteredMedicines,
              onDrugTap: (drug) => _navigateToDetails(context, drug),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Categories Section with header
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.medicalCategories,
                icon: LucideIcons.layoutGrid,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoriesSection(context, l10n),
              const SizedBox(height: 8),
              // Divider with decorative icon
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 8,
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    Icon(
                      LucideIcons.pill,
                      size: 12,
                      color: colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        indent: 8,
                        endIndent: 16,
                        color: colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Recently Updated Section
        if (!isInitialLoadComplete)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: SkeletonList(height: 200),
            ),
          )
        else if (medicineProvider.recentlyUpdatedDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  child: _buildHorizontalDrugList(
                    context,
                    title: l10n.recentlyUpdatedDrugs,
                    icon: LucideIcons.history, // Add icon
                    listHeight: 200,
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
                // Divider with decorative icon
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          indent: 16,
                          endIndent: 8,
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                      Icon(
                        LucideIcons.activity,
                        size: 12,
                        color: colorScheme.outlineVariant,
                      ),
                      Expanded(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          indent: 8,
                          endIndent: 16,
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Popular Drugs Section
        if (!medicineProvider.isInitialLoadComplete)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: SkeletonList(height: 200),
            ),
          )
        else if (medicineProvider.popularDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: _buildHorizontalDrugList(
                context,
                title: l10n.mostSearchedDrugs,
                icon: LucideIcons.flame, // Add icon
                listHeight: 200,
                drugs: medicineProvider.popularDrugs,
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
          ),

        // Bottom spacing
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  // Helper for building horizontal drug lists
  Widget _buildHorizontalDrugList(
    BuildContext context, {
    required String title,
    required List<DrugEntity> drugs,
    VoidCallback? onViewAll,
    double? listHeight,
    bool isPopular = false,
    IconData? icon, // Add icon parameter
  }) {
    return HorizontalListSection(
      title: title,
      icon: icon, // Pass icon to HorizontalListSection
      onViewAll: onViewAll,
      listHeight: listHeight, // Pass height to HorizontalListSection
      // Use constants for padding
      listPadding: const EdgeInsets.only(
        left: AppSpacing.large, // Use constant (16px)
        right: AppSpacing.large, // Use constant (16px)
        bottom: AppSpacing.large, // Use constant (16px) - Adjust if needed
      ),
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

  Widget _buildSearchBar(BuildContext context) {
    // This widget is now wrapped in SliverPadding in _buildContent
    return const SearchBarButton();
  }

  Widget _buildCategoriesSection(BuildContext context, AppLocalizations l10n) {
    // Add l10n parameter
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
        child: SkeletonList(height: 105, itemWidth: 100, itemCount: 4),
      );
    }
    if (englishCategories.isEmpty) {
      _logger.w("HomeScreen: No categories found to display.");
      return const SizedBox.shrink(); // Or EmptyStateWidget if desired
    }

    // Helper function to normalize keys (lowercase, replace space/uppercase with underscore)
    String normalizeKey(String key) {
      return key
          .replaceAllMapped(RegExp(r'([A-Z])'), (match) => '_${match.group(1)}')
          .replaceAll(' ', '_')
          .toLowerCase()
          .replaceAll(RegExp(r'^_+'), '');
    }

    // No longer filtering based on translation map keys
    final displayableCategories =
        englishCategories; // Use all fetched categories

    _logger.v(
      "HomeScreen: Displayable categories after filtering: ${displayableCategories.length}",
    );

    return HorizontalListSection(
      title: null, // Remove duplicate title - shown above in header
      listHeight: 105, // Keep height consistent
      // headerPadding removed
      // Use constants for padding
      listPadding: const EdgeInsets.only(
        left: AppSpacing.large, // Use constant (16px)
        right: AppSpacing.large, // Use constant (16px)
        bottom:
            AppSpacing
                .medium, // Use constant (12px) - Reduced bottom padding slightly
      ),
      children:
          // Iterate through the ORIGINAL English categories (keys from CSV)
          // Iterate through the ORIGINAL English categories (keys from CSV)
          displayableCategories.map((englishCategoryName) {
            // Determine locale for conditional translation
            final locale = Localizations.localeOf(context);
            final isArabic = locale.languageCode == 'ar';

            // 1. Normalize the key
            final normalizedKey = normalizeKey(englishCategoryName);

            // 2. Determine the display name based on locale
            final String displayName;
            if (isArabic) {
              // Use the ORIGINAL English name for translation lookup
              displayName =
                  kCategoryTranslation[englishCategoryName] ??
                  englishCategoryName; // Use translation if Arabic
            } else {
              displayName =
                  englishCategoryName; // Use original English name otherwise
            }

            // 3. Look up icon using the normalized key
            final iconData =
                kCategoryIcons[normalizedKey] ?? // Use normalized key for lookup
                kCategoryIcons['default']!;

            // 4. Build the card
            return CategoryCard(
                  key: ValueKey(
                    englishCategoryName,
                  ), // Use English name for stable key
                  name: displayName, // Use the locale-aware display name
                  iconData: iconData, // Use the looked-up icon
                  onTap: () {
                    _logger.i(
                      "HomeScreen: Category tapped: $displayName (English: $englishCategoryName)", // Use displayName in log
                    );
                    _adService.incrementUsageCounterAndShowAdIfNeeded();
                    // Set the category filter in the provider
                    context.read<MedicineProvider>().setCategory(
                      englishCategoryName,
                    );
                    // Navigate to SearchScreen, passing category as argument
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => SearchScreen(
                              initialCategory: englishCategoryName,
                            ),
                      ),
                    );
                  },
                )
                .animate()
                .scale(
                  delay:
                      (englishCategories.indexOf(englishCategoryName) *
                              100) // Use original list for index
                          .ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(
                  delay:
                      (englishCategories.indexOf(englishCategoryName) *
                              100) // Use original list for index
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

  Widget _buildErrorWidget(
    BuildContext context,
    String error,
    AppLocalizations l10n,
  ) {
    // Add l10n parameter
    _logger.w("HomeScreen: Building error widget: $error");
    return Container(
      alignment: Alignment.center,
      // Use constants for padding
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.xxlarge * 2, // Use constant (64px)
        horizontal: AppSpacing.xlarge, // Use constant (24px)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: Theme.of(context).colorScheme.error,
            size: 64.0, // Keep specific size for large icon
          ),
          AppSpacing.gapVLarge, // Use constant (16px)
          Text(
            l10n.errorOccurred, // Use localized string
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapVSmall, // Use constant (8px)
          Text(
            error,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              // Use theme style
              color: Theme.of(context).colorScheme.error.withOpacity(0.8),
              // fontSize: 16.0, // Inherit from bodyLarge
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapVXLarge, // Use constant (24px)
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.refreshCw), // Make icon const
            label: Text(l10n.retry), // Use localized string
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

  // Helper to count price increases/decreases in a list of drugs
  int _countPriceChanges(List<DrugEntity> drugs, bool isIncrease) {
    int count = 0;
    for (final drug in drugs) {
      final oldPrice = double.tryParse(drug.oldPrice ?? '0') ?? 0;
      final currentPrice = double.tryParse(drug.price) ?? 0;

      if (oldPrice > 0 && currentPrice > 0 && oldPrice != currentPrice) {
        if (isIncrease && currentPrice > oldPrice) {
          count++;
        } else if (!isIncrease && currentPrice < oldPrice) {
          count++;
        }
      }
    }
    return count;
  }

  // Helper to get top changed drugs sorted by percentage change
  List<DrugEntity> _getTopChangedDrugs(List<DrugEntity> drugs, int count) {
    final changedDrugs =
        drugs.where((drug) {
          final oldPrice = double.tryParse(drug.oldPrice ?? '0') ?? 0;
          final currentPrice = double.tryParse(drug.price) ?? 0;
          return oldPrice > 0 && currentPrice > 0 && oldPrice != currentPrice;
        }).toList();

    // Sort by percentage change (descending)
    changedDrugs.sort((a, b) {
      final oldPriceA = double.tryParse(a.oldPrice ?? '0') ?? 0;
      final currentPriceA = double.tryParse(a.price) ?? 0;
      final percentageA = ((currentPriceA - oldPriceA) / oldPriceA * 100).abs();

      final oldPriceB = double.tryParse(b.oldPrice ?? '0') ?? 0;
      final currentPriceB = double.tryParse(b.price) ?? 0;
      final percentageB = ((currentPriceB - oldPriceB) / oldPriceB * 100).abs();

      return percentageB.compareTo(percentageA);
    });

    return changedDrugs.take(count).toList();
  }
}
