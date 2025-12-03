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
              const HomeHeader(), // Contains its own padding
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
          sliver: SliverToBoxAdapter(
            child: const SearchBarButton(),
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        
        // Categories Section with header
        if (isInitialLoadComplete)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    l10n.medicalCategories,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategoriesSection(context, l10n),
                const SizedBox(height: 8),
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        
        // Recently Updated Section
        if (medicineProvider.isInitialLoadComplete &&
            medicineProvider.recentlyUpdatedDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 200,
                  child: _buildHorizontalDrugList(
                    context,
                    title: l10n.recentlyUpdatedDrugs,
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
                // Divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        
        // Popular Drugs Section
        if (medicineProvider.isInitialLoadComplete &&
            medicineProvider.popularDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200,
              child: _buildHorizontalDrugList(
                context,
                title: l10n.mostSearchedDrugs,
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
        const SliverPadding(
          padding: EdgeInsets.only(bottom: 24),
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
    double? listHeight, // Add listHeight parameter
    bool isPopular = false, // Add isPopular flag
  }) {
    return HorizontalListSection(
      title: title,
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
        height: 115, // Keep height consistent
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

    // No longer filtering based on translation map keys
    final displayableCategories =
        englishCategories; // Use all fetched categories

    _logger.v(
      "HomeScreen: Displayable categories after filtering: ${displayableCategories.length}",
    );

    return HorizontalListSection(
      title: l10n.medicalCategories, // Use localized string
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
}
