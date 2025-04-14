import 'dart:async'; // Import Timer for debounce
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/medicine_provider.dart'; // Corrected provider path
import '../widgets/filter_bottom_sheet.dart'; // Import the bottom sheet widget
import 'search_screen.dart'; // Import the new SearchScreen
import 'drug_details_screen.dart'; // Import the new details screen
// import '../widgets/drug_list_item.dart'; // Replaced by DrugCard
import '../widgets/drug_card.dart'; // Import DrugCard
import '../widgets/section_header.dart';
import '../widgets/home_header.dart'; // Import the new HomeHeader widget
import '../widgets/horizontal_list_section.dart';
import '../widgets/category_card.dart';
import '../widgets/banner_ad_widget.dart'; // Import Banner Ad Widget
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/di/locator.dart'; // Import locator
import '../../core/services/file_logger_service.dart'; // Import logger
import '../services/ad_service.dart'; // Import AdService
// DI is now handled by locator.dart and main.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Get AdService instance
  final AdService _adService = locator<AdService>();
  final FileLoggerService _logger =
      locator<FileLoggerService>(); // Get logger instance

  @override
  Widget build(BuildContext context) {
    _logger.i("HomeScreen: Building widget...");
    // Restore Original Build Logic
    final medicineProvider = context.watch<MedicineProvider>();
    final isLoading = medicineProvider.isLoading;
    final error = medicineProvider.error;
    // Use filteredMedicines which is populated by loadInitialData/_applyFilters
    final displayedMedicines = medicineProvider.filteredMedicines;
    _logger.d(
      "HomeScreen: State - isLoading: $isLoading, error: '$error', displayedMedicines: ${displayedMedicines.length}",
    );

    return Scaffold(
      // Wrap body with Column to add BannerAdWidget at the bottom
      body: Column(
        children: [
          Expanded(
            // Make the main content scrollable and take available space
            child: RefreshIndicator(
              onRefresh: () {
                _logger.i("HomeScreen: RefreshIndicator triggered.");
                return context.read<MedicineProvider>().loadInitialData();
              },
              child:
                  isLoading &&
                          displayedMedicines
                              .isEmpty // Show loading only if list is truly empty
                      ? _buildLoadingIndicator()
                      : error.isNotEmpty &&
                          displayedMedicines
                              .isEmpty // Show error only if list is empty
                      ? _buildErrorWidget(context, error)
                      : _buildContent(
                        context,
                        medicineProvider,
                        displayedMedicines,
                      ), // Build main content
            ),
          ),
          // Add Banner Ad at the bottom
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    _logger.v("HomeScreen: Building loading indicator.");
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent(
    BuildContext context,
    MedicineProvider medicineProvider,
    List<DrugEntity> displayedMedicines,
  ) {
    _logger.v("HomeScreen: Building main content ListView.");
    return ListView(
      padding: EdgeInsets.zero, // Remove default padding
      children: [
        const HomeHeader(), // Use the new HomeHeader widget
        _buildSearchBar(context),
        const SizedBox(height: 16.0),
        // --- Categories Section ---
        _buildCategoriesSection(context), // Use HorizontalListSection
        const SizedBox(height: 16.0),

        // --- Recently Updated Section (Removed Temporarily) ---
        // if (recentlyUpdated.isNotEmpty) ...

        // --- Popular Drugs Section (Removed Temporarily) ---
        // HorizontalListSection(...)
        const SizedBox(height: 16.0), // Keep spacing
        // --- All Drugs Section ---
        // Title changes based on whether filters are active
        SectionHeader(
          title:
              medicineProvider.searchQuery.isEmpty &&
                      medicineProvider.selectedCategory.isEmpty
                  ? 'جميع الأدوية'
                  : 'نتائج البحث/الفلترة',
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        _buildAllDrugsList(
          context,
          displayedMedicines,
        ) // Use displayedMedicines
        .animate().fadeIn(duration: 500.ms, delay: 400.ms),
      ],
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
          // Increment ad counter when search is initiated
          _adService.incrementUsageCounterAndShowAdIfNeeded();
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => const SearchScreen()),
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
    final categories =
        context
            .watch<MedicineProvider>()
            .categories; // Get categories from provider
    _logger.v(
      "HomeScreen: Building categories section with ${categories.length} categories.",
    );
    // Placeholder icons - replace if specific icons become available
    final categoryIcons = {
      'مسكنات الألم': Icons.healing_outlined, // Example mapping
      'مضادات حيوية': Icons.medication_liquid_outlined,
      'أمراض مزمنة': Icons.monitor_heart_outlined,
      'فيتامينات': Icons.local_florist_outlined,
      // Add more mappings as needed based on actual category names from DB
    };

    return HorizontalListSection(
      title: 'الفئات الطبية',
      listHeight: 115, // Height for category cards
      headerPadding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 8,
      ),
      children:
          categories.map((categoryName) {
            // Iterate over category names (String)
            // Use the new CategoryCard widget
            return CategoryCard(
                  name: categoryName, // Use name directly from provider list
                  iconData:
                      categoryIcons[categoryName] ??
                      Icons.category, // Get icon from map or default
                  onTap: () {
                    _logger.i("HomeScreen: Category tapped: $categoryName");
                    // Increment ad counter when category is tapped
                    _adService.incrementUsageCounterAndShowAdIfNeeded();
                    context.read<MedicineProvider>().setCategory(
                      categoryName,
                    ); // Filter by this category name
                  },
                )
                .animate() // Apply animation to the CategoryCard itself
                .scale(
                  delay: (categories.indexOf(categoryName) * 100).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                ) // Use categoryName here
                .fadeIn(
                  delay: (categories.indexOf(categoryName) * 100).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ); // Use categoryName here
          }).toList(),
    );
  }

  void _navigateToDetails(BuildContext context, DrugEntity drug) {
    _logger.i("HomeScreen: Navigating to details for drug: ${drug.tradeName}");
    // Increment ad counter before navigating
    _adService.incrementUsageCounterAndShowAdIfNeeded();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrugDetailsScreen(drug: drug)),
    );
  }

  Widget _buildAllDrugsList(BuildContext context, List<DrugEntity> medicines) {
    _logger.v(
      "HomeScreen: Building all drugs list with ${medicines.length} items.",
    );
    if (medicines.isEmpty) {
      // Show a different message if filters are active but no results
      final provider = context.read<MedicineProvider>();
      final bool filtersActive =
          provider.searchQuery.isNotEmpty ||
          provider.selectedCategory.isNotEmpty;
      _logger.v(
        "HomeScreen: No drugs to display. Filters active: $filtersActive",
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
        child: Center(
          child: Text(
            filtersActive
                ? 'لا توجد نتائج تطابق الفلاتر الحالية.'
                : 'لا توجد أدوية لعرضها حالياً.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).hintColor),
          ),
        ),
      );
    }
    // Use ListView.builder within the main ListView
    return ListView.builder(
      shrinkWrap: true, // Important inside another scroll view
      physics:
          const NeverScrollableScrollPhysics(), // Disable its own scrolling
      itemCount: medicines.length,
      itemBuilder: (context, index) {
        final drug = medicines[index];
        // Use DrugCard (detailed) instead of DrugListItem
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ), // Add padding
          child: DrugCard(
            // Use DrugCard (detailed)
            drug: drug,
            type: DrugCardType.detailed,
            onTap: () => _navigateToDetails(context, drug), // Use helper
          ),
        );
      },
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
              color:
                  Theme.of(context).colorScheme.error, // Use theme error color
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
