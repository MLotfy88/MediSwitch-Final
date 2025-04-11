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
import '../widgets/category_card.dart'; // Import CategoryCard
import 'package:flutter_animate/flutter_animate.dart';
// DI is now handled by locator.dart and main.dart
// import '../../main.dart'; // Removed
// import '../../domain/usecases/find_drug_alternatives.dart'; // Removed
// import '../bloc/alternatives_provider.dart'; // Removed
// import '../screens/alternatives_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final medicineProvider = context.watch<MedicineProvider>();
    final isLoading = medicineProvider.isLoading;
    final error = medicineProvider.error;
    // Get full list for main display, recently updated list for its section
    final allMedicines = medicineProvider.medicines; // Use the full list
    final recentlyUpdated = medicineProvider.recentlyUpdatedMedicines;
    // TODO: Add logic for popular medicines if needed

    // Apply the overall fade-in animation from the design
    return Scaffold(
      // No AppBar here, Header component will be part of the body
      body: RefreshIndicator(
        onRefresh: () => context.read<MedicineProvider>().loadInitialData(),
        child:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : error.isNotEmpty
                ? _buildErrorWidget(context, error) // Keep error handling
                : ListView(
                  // Use ListView instead of CustomScrollView
                  padding: EdgeInsets.zero, // Remove default padding
                  children: [
                    const HomeHeader(), // Use the new HomeHeader widget
                    _buildSearchBar(context),
                    const SizedBox(height: 16.0),
                    // --- Categories Section ---
                    _buildCategoriesSection(
                      context,
                    ), // Use HorizontalListSection
                    const SizedBox(height: 16.0),
                    // --- Recently Updated Section ---
                    if (recentlyUpdated.isNotEmpty)
                      HorizontalListSection(
                        title: 'أدوية محدثة مؤخراً',
                        listHeight: 210, // Match previous SizedBox height
                        onViewAll: () {
                          print("View All Recently Updated Tapped");
                        },
                        children:
                            recentlyUpdated
                                .map(
                                  (drug) => SizedBox(
                                    width: 170, // Match previous SizedBox width
                                    child: DrugCard(
                                      // Use DrugCard (thumbnail)
                                      drug: drug,
                                      type: DrugCardType.thumbnail,
                                      onTap:
                                          () =>
                                              _navigateToDetails(context, drug),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),

                    // --- Popular Drugs Section ---
                    HorizontalListSection(
                      title: 'الأدوية الأكثر بحثاً',
                      listHeight: 210, // Match previous SizedBox height
                      onViewAll: () {
                        print("View All Popular Drugs Tapped");
                      },
                      children:
                          medicineProvider.popularDrugs
                              .map(
                                (drug) => SizedBox(
                                  width: 170, // Match previous SizedBox width
                                  child: DrugCard(
                                    // Use DrugCard (thumbnail)
                                    drug: drug,
                                    type: DrugCardType.thumbnail,
                                    onTap:
                                        () => _navigateToDetails(context, drug),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(
                      height: 16.0,
                    ), // Keep spacing after popular drugs
                    // --- All Drugs Section ---
                    const SectionHeader(
                      title: 'جميع الأدوية',
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ), // Add header
                    _buildAllDrugsList(context, allMedicines).animate().fadeIn(
                      duration: 500.ms,
                      delay: 400.ms,
                    ), // Add fade-in
                  ],
                ),
      ),
    );
  }

  // --- Builder Methods ---

  // Builds the search bar section (placeholder for now, might become a separate widget)
  Widget _buildSearchBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
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

  // Removed _buildHeader method - replaced by HomeHeader widget

  // Builds the Categories section using HorizontalListSection
  // Renamed from _buildCategoriesGrid
  Widget _buildCategoriesSection(BuildContext context) {
    // Placeholder categories - replace with actual data source later
    final categories = [
      {
        'name': 'مسكنات الألم',
        'icon': Icons.healing_outlined,
        'data': 'pain_management',
      },
      {
        'name': 'مضادات حيوية',
        'icon': Icons.medication_liquid_outlined,
        'data': 'antibiotics',
      },
      {
        'name': 'أمراض مزمنة',
        'icon': Icons.monitor_heart_outlined,
        'data': 'chronic',
      },
      {
        'name': 'فيتامينات',
        'icon': Icons.local_florist_outlined,
        'data': 'vitamins',
      },
    ];

    return HorizontalListSection(
      title: 'الفئات الطبية',
      listHeight: 115, // Height for category cards
      // Remove header padding as it's handled by the section widget now
      headerPadding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 8,
      ),
      children:
          categories.map((category) {
            // Use the new CategoryCard widget
            return CategoryCard(
                  name: category['name'] as String? ?? '',
                  iconData:
                      category['icon'] as IconData? ??
                      Icons.category, // Provide default icon
                  onTap: () {
                    context.read<MedicineProvider>().setCategory(
                      category['data'] as String? ?? '',
                    );
                    print("Category Tapped: ${category['name']}");
                  },
                )
                .animate() // Apply animation to the CategoryCard itself
                .scale(
                  delay: (categories.indexOf(category) * 100).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(
                  delay: (categories.indexOf(category) * 100).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                );
          }).toList(),
    );
  }

  // Removed _buildCategoriesGrid and _buildHorizontalDrugList methods
  // They are now handled by HorizontalListSection

  // Helper method for navigation to avoid repetition
  void _navigateToDetails(BuildContext context, DrugEntity drug) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrugDetailsScreen(drug: drug)),
    );
  }

  // Builds the vertical list for "All Drugs" section
  Widget _buildAllDrugsList(BuildContext context, List<DrugEntity> medicines) {
    if (medicines.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: Text('لا توجد أدوية لعرضها.')),
      );
    }
    // Use ListView.builder within the main ListView
    // Need to set physics and shrinkWrap appropriately
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

  // Removed _buildDrugListOrGrid as it's replaced by _buildAllDrugsList
  Widget _buildErrorWidget(BuildContext context, String error) {
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
              onPressed:
                  () => context.read<MedicineProvider>().loadInitialData(),
            ),
          ],
        ),
      ),
    );
  }
}
