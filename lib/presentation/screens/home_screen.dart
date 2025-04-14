import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart';
import '../bloc/medicine_provider.dart';
import '../widgets/filter_bottom_sheet.dart'; // Keep for potential future use
import 'search_screen.dart';
import 'drug_details_screen.dart';
import '../widgets/drug_card.dart';
import '../widgets/section_header.dart';
import '../widgets/home_header.dart';
import '../widgets/horizontal_list_section.dart';
import '../widgets/category_card.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdService _adService = locator<AdService>();
  final FileLoggerService _logger = locator<FileLoggerService>();
  final ScrollController _scrollController =
      ScrollController(); // Add ScrollController

  @override
  void initState() {
    super.initState();
    _logger.i("HomeScreen: initState called.");
    // Add listener to ScrollController for pagination
    _scrollController.addListener(_onScroll);
    // Initial data load is triggered by MedicineProvider constructor
  }

  @override
  void dispose() {
    _logger.i("HomeScreen: dispose called.");
    _scrollController.removeListener(_onScroll); // Remove listener
    _scrollController.dispose(); // Dispose controller
    super.dispose();
  }

  // Listener for scroll events
  void _onScroll() {
    // Check if near the bottom and more items exist and not already loading more
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent -
                300 && // Trigger slightly earlier
        context.read<MedicineProvider>().hasMoreItems &&
        !context.read<MedicineProvider>().isLoadingMore &&
        !context
            .read<MedicineProvider>()
            .isLoading) // Also check main loading flag
    {
      _logger.i("HomeScreen: Reached near bottom, calling loadMoreDrugs...");
      // Use try-catch for safety, although provider should handle errors
      try {
        context.read<MedicineProvider>().loadMoreDrugs();
      } catch (e, s) {
        _logger.e("HomeScreen: Error calling loadMoreDrugs", e, s);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("HomeScreen: Building widget...");
    // Use Consumer for more granular rebuilds if needed, but watch is fine for now
    final medicineProvider = context.watch<MedicineProvider>();
    final isLoading = medicineProvider.isLoading;
    final isLoadingMore =
        medicineProvider.isLoadingMore; // Get loading more state
    final error = medicineProvider.error;
    final displayedMedicines = medicineProvider.filteredMedicines;
    _logger.d(
      "HomeScreen: State - isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: '$error', displayedMedicines: ${displayedMedicines.length}, hasMore: ${medicineProvider.hasMoreItems}",
    );

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                _logger.i("HomeScreen: RefreshIndicator triggered.");
                return context
                    .read<MedicineProvider>()
                    .loadInitialData(); // Reset to page 0
              },
              child:
                  isLoading && displayedMedicines.isEmpty
                      ? _buildLoadingIndicator()
                      // Pass isLoading to _buildContent
                      : _buildContent(
                        context,
                        medicineProvider,
                        displayedMedicines,
                        isLoading,
                        isLoadingMore,
                        error,
                      ),
            ),
          ),
          const BannerAdWidget(), // Keep banner ad
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    _logger.v("HomeScreen: Building loading indicator.");
    return const Center(child: CircularProgressIndicator());
  }

  // Modify _buildContent to accept isLoading, isLoadingMore and error
  Widget _buildContent(
    BuildContext context,
    MedicineProvider medicineProvider,
    List<DrugEntity> displayedMedicines,
    bool isLoading,
    bool isLoadingMore,
    String error,
  ) {
    _logger.v("HomeScreen: Building main content ListView.");
    // Handle error state first if list is empty
    if (error.isNotEmpty && displayedMedicines.isEmpty) {
      return _buildErrorWidget(context, error);
    }

    // Use ListView.builder directly and attach the controller
    return ListView.builder(
      controller: _scrollController, // Attach controller
      padding: EdgeInsets.zero,
      // Add 1 to itemCount for the potential loading indicator or end message
      itemCount:
          displayedMedicines.length +
          1, // Always reserve space for indicator/end message
      itemBuilder: (context, index) {
        // --- Build Header, Search, Categories only once at the top ---
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeHeader(),
              _buildSearchBar(context),
              const SizedBox(height: 16.0),
              _buildCategoriesSection(context),
              const SizedBox(height: 16.0),
              // --- All Drugs Section Header ---
              SectionHeader(
                title:
                    medicineProvider.searchQuery.isEmpty &&
                            medicineProvider.selectedCategory.isEmpty
                        ? 'الأدوية' // Simplified title
                        : 'نتائج البحث/الفلترة',
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              // If the list is empty AFTER header, show empty message
              // Use the passed isLoading parameter here
              if (displayedMedicines.isEmpty &&
                  !isLoading &&
                  !isLoadingMore &&
                  error.isEmpty)
                _buildEmptyListMessage(context, medicineProvider),
            ],
          );
        }

        // --- Build Drug Items (adjust index for header) ---
        final itemIndex = index - 1; // Adjust index because header is item 0

        if (itemIndex < displayedMedicines.length) {
          final drug = displayedMedicines[itemIndex];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: DrugCard(
              drug: drug,
              type: DrugCardType.detailed,
              onTap: () => _navigateToDetails(context, drug),
            ),
          ).animate().fadeIn(
            delay: (itemIndex % 10 * 50).ms,
          ); // Staggered fade-in
        }
        // --- Build Loading Indicator or End Message ---
        else if (isLoadingMore) {
          _logger.v(
            "HomeScreen: Building loading more indicator at end of list.",
          );
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (!medicineProvider.hasMoreItems &&
            displayedMedicines.isNotEmpty) {
          // Only show if list not empty
          _logger.v("HomeScreen: Building 'end of list' message.");
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 32.0,
              horizontal: 16.0,
            ),
            child: Center(
              child: Text(
                'وصلت إلى نهاية القائمة',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          );
        } else {
          // If hasMoreItems is true but not loading, or if list is empty initially, show nothing at the end
          return Container(height: 0); // Return empty container
        }
      },
    );
  }

  // --- Builder Methods ---

  Widget _buildSearchBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          _logger.i("HomeScreen: Search bar tapped.");
          _adService.incrementUsageCounterAndShowAdIfNeeded();
          Navigator.push(
            context,
            // Pass empty query to SearchScreen to show all initially
            MaterialPageRoute<void>(
              builder: (context) => const SearchScreen(initialQuery: ''),
            ), // Keep error for now
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color:
                colorScheme.brightness == Brightness.dark
                    ? colorScheme.surfaceVariant
                    : Colors.white,
            borderRadius: BorderRadius.circular(28.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Theme.of(context).hintColor, size: 22),
              const SizedBox(width: 10.0),
              Text(
                'ابحث عن دواء...',
                style: textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = context.watch<MedicineProvider>().categories;
    _logger.v(
      "HomeScreen: Building categories section with ${categories.length} categories.",
    );
    final categoryIcons = {
      'مسكنات الألم': Icons.healing_outlined,
      'مضادات حيوية': Icons.medication_liquid_outlined,
      'أمراض مزمنة': Icons.monitor_heart_outlined,
      'فيتامينات': Icons.local_florist_outlined,
    };

    // Handle case where categories might still be loading
    if (categories.isEmpty && context.watch<MedicineProvider>().isLoading) {
      return const SizedBox(
        height: 115,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (categories.isEmpty) {
      return const SizedBox.shrink(); // Don't show section if no categories
    }

    return HorizontalListSection(
      title: 'الفئات الطبية',
      listHeight: 115,
      headerPadding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 8,
      ),
      children:
          categories.map((categoryName) {
            return CategoryCard(
                  name: categoryName,
                  iconData: categoryIcons[categoryName] ?? Icons.category,
                  onTap: () {
                    _logger.i("HomeScreen: Category tapped: $categoryName");
                    _adService.incrementUsageCounterAndShowAdIfNeeded();
                    context.read<MedicineProvider>().setCategory(categoryName);
                  },
                )
                .animate()
                .scale(
                  delay: (categories.indexOf(categoryName) * 100).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(
                  delay: (categories.indexOf(categoryName) * 100).ms,
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

  // Add helper for empty list message
  Widget _buildEmptyListMessage(
    BuildContext context,
    MedicineProvider provider,
  ) {
    final bool filtersActive =
        provider.searchQuery.isNotEmpty || provider.selectedCategory.isNotEmpty;
    _logger.v(
      "HomeScreen: Building empty list message. Filters active: $filtersActive",
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
      child: Center(
        child: Text(
          filtersActive
              ? 'لا توجد نتائج تطابق الفلاتر الحالية.'
              : 'لا توجد أدوية لعرضها حالياً.', // This might show briefly on initial load
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).hintColor),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    _logger.w("HomeScreen: Building error widget: $error");
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              error,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: () {
                _logger.i("HomeScreen: Retry button pressed.");
                context.read<MedicineProvider>().loadInitialData();
              },
            ),
          ],
        ),
      ),
    );
  }
}
