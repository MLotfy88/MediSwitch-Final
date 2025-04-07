import 'dart:async'; // Import Timer for debounce
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/medicine_provider.dart'; // Corrected provider path
import '../widgets/filter_bottom_sheet.dart'; // Import the bottom sheet widget
import 'search_screen.dart'; // Import the new SearchScreen
import 'drug_details_screen.dart'; // Import the new details screen
import '../widgets/drug_list_item.dart'; // Import the list item widget
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
                _buildSectionHeader(context, 'الفئات الطبية'), // Updated title
                _buildCategoriesGrid(context),
                const SizedBox(height: 16.0),

                // --- Recently Updated Section ---
                if (!isLoading &&
                    error.isEmpty &&
                    recentlyUpdated.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'أدوية محدثة مؤخراً',
                    showViewAll: true,
                    onVewAllTap: () {
                      // TODO: Implement navigation to a "Recently Updated" screen or filter
                      print("View All Recently Updated Tapped");
                    },
                  ),
                  _buildHorizontalDrugList(context, recentlyUpdated),
                  const SizedBox(height: 16.0),
                ],

                // --- Popular Drugs Section (Placeholder) ---
                _buildSectionHeader(
                  context,
                  'الأدوية الأكثر بحثاً',
                  showViewAll: true,
                  onVewAllTap: () {
                    // TODO: Implement navigation to a "Popular Drugs" screen or filter
                    print("View All Popular Drugs Tapped");
                  },
                ),
                _buildHorizontalDrugList(
                  context,
                  allMedicines.take(5).toList(),
                ), // Placeholder with first 5 drugs
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
    // Mimics the header structure from the prototype
    return Container(
      padding: const EdgeInsets.only(
        top: 40.0,
        left: 20.0,
        right: 20.0,
        bottom: 24.0,
      ), // More padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ), // More curve
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end, // Align content to bottom
        children: [
          // User Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً، أحمد', // Placeholder name
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ابحث عن أدويتك بسهولة', // Updated subtitle from prototype
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              CircleAvatar(
                // Using CircleAvatar for consistency
                radius: 28, // Slightly larger
                backgroundColor: Colors.white.withOpacity(0.3),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24.0),
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
                horizontal: 20.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.surface, // Use surface color
                borderRadius: BorderRadius.circular(28.0), // Fully rounded
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Theme.of(context).hintColor),
                  const SizedBox(width: 12.0),
                  Text(
                    'ابحث عن دواء...',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    bool showViewAll = false,
    VoidCallback? onVewAllTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 20.0,
        bottom: 12.0,
      ), // Adjusted padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ), // Bolder title
          ),
          if (showViewAll)
            TextButton(
              onPressed: onVewAllTap,
              child: const Text('عرض الكل'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                textStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

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
          return InkWell(
            onTap: () {
              // Use setCategory from provider
              context.read<MedicineProvider>().setCategory(
                category['data'] as String? ?? '',
              );
              print("Category Tapped: ${category['name']}");
            },
            borderRadius: BorderRadius.circular(16.0), // More rounded
            child: Container(
              width: 95, // Fixed width
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 8.0,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(
                  0.5,
                ), // Slightly different background
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  // Add subtle shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      category['icon'] as IconData?,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    category['name'] as String? ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ), // Slightly bolder text
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
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
