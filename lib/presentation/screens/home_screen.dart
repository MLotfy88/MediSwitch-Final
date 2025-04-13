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

  @override
  Widget build(BuildContext context) {
    // --- Temporarily Simplify HomeScreen Build for Testing ---
    print("HomeScreen: Building simplified view...");
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text("Simplified HomeScreen Loading..."),
          ],
        ),
      ),
    );
    // --- End of Simplified Build ---

    /* // Original Build Logic Commented Out
    final medicineProvider = context.watch<MedicineProvider>();
    final isLoading = medicineProvider.isLoading;
    final error = medicineProvider.error;
    // Use filteredMedicines which is populated by loadInitialData/_applyFilters
    final displayedMedicines = medicineProvider.filteredMedicines;
    // Removed recentlyUpdated and popularDrugs as they are no longer pre-loaded

    return Scaffold(
      // Wrap body with Column to add BannerAdWidget at the bottom
      body: Column(
        children: [
          Expanded( // Make the main content scrollable and take available space
            child: RefreshIndicator(
              onRefresh: () => context.read<MedicineProvider>().loadInitialData(),
              child: isLoading && displayedMedicines.isEmpty // Show loading only if list is truly empty
                  ? const Center(child: CircularProgressIndicator())
                  : error.isNotEmpty && displayedMedicines.isEmpty // Show error only if list is empty
                  ? _buildErrorWidget(context, error)
                  : ListView(
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
                          title: medicineProvider.searchQuery.isEmpty && medicineProvider.selectedCategory.isEmpty
                                 ? 'جميع الأدوية'
                                 : 'نتائج البحث/الفلترة',
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        _buildAllDrugsList(context, displayedMedicines) // Use displayedMedicines
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 400.ms),
                      ],
                    ),
            ),
          ),
          // Add Banner Ad at the bottom
          const BannerAdWidget(),
        ],
      ),
    );
    */
  }

  // --- Builder Methods (Keep commented out for now) ---
  /*
  Widget _buildSearchBar(BuildContext context) {
     // ... (implementation) ...
  }

  Widget _buildCategoriesSection(BuildContext context) {
    // ... (implementation) ...
  }

  void _navigateToDetails(BuildContext context, DrugEntity drug) {
     // ... (implementation) ...
  }

  Widget _buildAllDrugsList(BuildContext context, List<DrugEntity> medicines) {
     // ... (implementation) ...
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    // ... (implementation) ...
  }
  */
}
