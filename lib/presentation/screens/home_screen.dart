import 'dart:async'; // Import Timer for debounce
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/medicine_provider.dart'; // Corrected provider path
import '../widgets/filter_bottom_sheet.dart'; // Import the bottom sheet widget
import 'search_screen.dart'; // Import the new SearchScreen
import 'drug_details_screen.dart'; // Import the new details screen
import '../widgets/drug_list_item.dart';
import '../widgets/section_header.dart'; // Import the new header widget
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate for extensions like .ms
// TODO: Remove temporary DI access via MyApp once proper DI is set up
// import '../../main.dart';
// import '../../domain/usecases/find_drug_alternatives.dart';
// import '../bloc/alternatives_provider.dart';
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

    return Scaffold(
      // AppBar is handled by MainScreen now, so removed from here.
      body: RefreshIndicator(
        // Add pull-to-refresh
        onRefresh: () => context.read<MedicineProvider>().loadInitialData(),
        child: CustomScrollView(
          // Use CustomScrollView for more complex layouts
          slivers: <Widget>[
            // --- Header Section ---
            SliverAppBar(
              expandedHeight: 180.0, // Adjust height as needed
              backgroundColor:
                  Colors.transparent, // Make background transparent
              elevation: 0,
              pinned: true, // Keep header visible while scrolling up
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(
                  context,
                ), // Use a separate header builder
                // Prevent title from showing when collapsed
                titlePadding: EdgeInsets.zero,
                centerTitle: true,
                title: const SizedBox.shrink(), // Hide title when collapsed
              ),
              // Add actions directly here if needed when this screen is standalone
              // actions: [ _buildFilterButton(context), _buildRefreshButton(context, isLoading, medicineProvider) ],
            ),

            // --- Body Content ---
            SliverList(
              delegate: SliverChildListDelegate([
                // --- Categories Section ---
                const SectionHeader(title: 'الفئات الطبية'), // Use new widget
                _buildCategoriesGrid(context),
                const SizedBox(height: 16.0),

                // --- Recently Updated Section ---
                if (!isLoading &&
                    error.isEmpty &&
                    recentlyUpdated.isNotEmpty) ...[
                  SectionHeader(
                    // Use new widget
                    title: 'أدوية محدثة مؤخراً',
                    action: TextButton(
                      // Define action widget directly
                      onPressed: () {
                        // TODO: Implement navigation
                        print("View All Recently Updated Tapped");
                      },
                      child: const Text('عرض الكل'),
                    ),
                  ),
                  _buildHorizontalDrugList(context, recentlyUpdated),
                  const SizedBox(height: 16.0),
                ],

                // --- Popular Drugs Section ---
                SectionHeader(
                  // Use new widget
                  title: 'الأدوية الأكثر بحثاً',
                  action: TextButton(
                    // Define action widget directly
                    onPressed: () {
                      // TODO: Implement navigation
                      print("View All Popular Drugs Tapped");
                    },
                    child: const Text('عرض الكل'),
                  ),
                ),
                _buildHorizontalDrugList(
                  context,
                  medicineProvider
                      .popularDrugs, // Use actual popular drugs list
                ),
                const SizedBox(height: 16.0),

                // --- Main Drug List Title ---
                // Removed "All Drugs" title as it might be redundant if filtering is clear
                // _buildSectionHeader(context, 'جميع الأدوية'),
              ]),
            ),

            // --- Loading/Error/Grid/List Section ---
            SliverPadding(
              // Add padding around the main list/grid
              padding: const EdgeInsets.all(12.0), // Slightly more padding
              sliver:
                  isLoading
                      ? const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : error.isNotEmpty
                      ? SliverFillRemaining(
                        child: _buildErrorWidget(context, error),
                      )
                      : _buildDrugListOrGrid(context, allMedicines),
            ),
          ],
        ),
      ),
    );
  }

  // --- Builder Methods ---

  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // Mimics the header structure from the prototype
    // Using SafeArea to avoid status bar overlap
    return SafeArea(
      bottom: false, // Only apply padding to the top
      child: Container(
        padding: const EdgeInsets.only(
          top: 16.0, // Reduced top padding inside SafeArea
          left: 20.0,
          right: 20.0,
          bottom: 20.0, // Reduced bottom padding
        ),
        // Removed gradient background, AppBar handles background now
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end, // Align content to bottom
          children: [
            // User Info Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، أحمد', // Placeholder name
                      style: textTheme.titleLarge?.copyWith(
                        // Use AppBar's foreground color or a contrasting color
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2), // Reduced spacing
                    Text(
                      'ابحث عن أدويتك بسهولة',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 26, // Adjusted size
                  backgroundColor: colorScheme.onPrimary.withOpacity(0.15),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 28, // Adjusted size
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18.0), // Adjusted spacing
            // Search Bar
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, // Adjusted padding
                  vertical: 12.0, // Adjusted padding
                ),
                decoration: BoxDecoration(
                  // Use a slightly different color for contrast if AppBar is primary
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
                    Icon(
                      Icons.search,
                      color: Theme.of(context).hintColor,
                      size: 22, // Adjusted size
                    ),
                    const SizedBox(width: 10.0), // Adjusted spacing
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
          ],
        ),
      ),
    ); // Add missing closing brace for SafeArea
  }

  // Removed _buildSectionHeader - replaced by SectionHeader widget
  Widget _buildCategoriesGrid(BuildContext context) {
    // Categories based on prototype
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
      // Add more if needed
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 115, // Adjusted height
      child: ListView.separated(
        // Use ListView for horizontal scroll
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder:
            (context, index) =>
                const SizedBox(width: 16.0), // Increased spacing
        itemBuilder: (context, index) {
          final category = categories[index];
          // Wrap InkWell with Animate to add tap effect
          return InkWell(
            onTap: () {
              context.read<MedicineProvider>().setCategory(
                category['data'] as String? ?? '',
              );
              print("Category Tapped: ${category['name']}");
            },
            borderRadius: BorderRadius.circular(16.0),
            child: Card(
                  // Apply animation to the Card
                  elevation: 1.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.7),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14.0,
                      horizontal: 8.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            category['icon'] as IconData?,
                            size: 30,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          category['name'] as String? ?? '',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ) // End Card
                .animate() // Apply animate to Card
                .scale(
                  // Add scale effect on tap - This will play on build, not tap
                  // To trigger on tap, you'd need a stateful widget or AnimationController
                  // For simplicity, let's just have a build-time animation for now
                  delay: (100 * index).ms, // Stagger the animation
                  duration: 400.ms,
                  curve: Curves.easeOut,
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(
                  // Also fade in
                  delay: (100 * index).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                ), // End animate chain
          ); // End InkWell
        },
      ),
    );
  }

  // Updated to use DrugListItem which now includes image handling
  Widget _buildHorizontalDrugList(
    BuildContext context,
    List<DrugEntity> drugs,
  ) {
    return SizedBox(
      height: 210, // Increased height for better card display with image
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: drugs.length,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemBuilder: (context, index) {
          final drug = drugs[index];
          return SizedBox(
            width: 170, // Adjusted width
            child: DrugListItem(
              // Use the imported widget
              drug: drug,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DrugDetailsScreen(drug: drug),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrugListOrGrid(
    BuildContext context,
    List<DrugEntity> medicines,
  ) {
    if (medicines.isEmpty) {
      return const SliverFillRemaining(
        // Use SliverFillRemaining for empty state in CustomScrollView
        child: Center(child: Text('لا توجد أدوية متطابقة.')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const double gridBreakpoint = 600.0;
        final bool useGridView = constraints.maxWidth >= gridBreakpoint;
        // Adjust crossAxisCount and childAspectRatio based on DrugListItem's new layout
        final int crossAxisCount =
            useGridView ? (constraints.maxWidth / 200).floor().clamp(2, 4) : 1;
        final double childAspectRatio =
            useGridView ? 0.8 : 2.5; // Adjust aspect ratio

        if (useGridView) {
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final drug = medicines[index];
              return DrugListItem(
                drug: drug,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DrugDetailsScreen(drug: drug),
                    ),
                  );
                },
              );
            }, childCount: medicines.length),
          );
        } else {
          // Use ListView for narrower screens
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final drug = medicines[index];
              return DrugListItem(
                drug: drug,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DrugDetailsScreen(drug: drug),
                    ),
                  );
                },
              );
            }, childCount: medicines.length),
          );
        }
      },
    );
  }

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
