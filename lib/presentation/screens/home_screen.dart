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
import '../../main.dart';
import '../../domain/usecases/find_drug_alternatives.dart';
import '../bloc/alternatives_provider.dart';
import '../screens/alternatives_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Removed search controller and category state as search/filter handled elsewhere now

  @override
  Widget build(BuildContext context) {
    final medicineProvider = context.watch<MedicineProvider>();
    final isLoading = medicineProvider.isLoading;
    final error = medicineProvider.error;
    // Get full list for main display, recently updated list for its section
    final allMedicines = medicineProvider.medicines; // Use the full list
    final recentlyUpdated = medicineProvider.recentlyUpdatedMedicines;

    return Scaffold(
      // AppBar is handled by MainScreen now, so removed from here.
      // If this screen needs a specific AppBar when standalone, add it back.
      body: RefreshIndicator(
        // Add pull-to-refresh
        onRefresh:
            () =>
                context
                    .read<MedicineProvider>()
                    .loadInitialData(), // Corrected call
        child: CustomScrollView(
          // Use CustomScrollView for more complex layouts
          slivers: <Widget>[
            // --- Header Section (AppBar replacement) ---
            SliverAppBar(
              expandedHeight: 180.0, // Adjust height as needed
              backgroundColor:
                  Colors.transparent, // Make background transparent
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(
                  context,
                ), // Use a separate header builder
              ),
              // Add actions directly here if needed when this screen is standalone
              // actions: [ _buildFilterButton(context), _buildRefreshButton(context, isLoading, medicineProvider) ],
            ),

            // --- Body Content ---
            SliverList(
              delegate: SliverChildListDelegate([
                // --- Categories Section ---
                _buildSectionHeader(context, 'الفئات'),
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

                // --- Main Drug List Title ---
                _buildSectionHeader(
                  context,
                  'جميع الأدوية',
                ), // Title for the main list
              ]),
            ),

            // --- Loading/Error/Grid/List Section ---
            SliverPadding(
              // Add padding around the main list/grid
              padding: const EdgeInsets.all(8.0),
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
    return Container(
      padding: const EdgeInsets.only(
        top: 40.0,
        left: 16.0,
        right: 16.0,
        bottom: 20.0,
      ), // Adjusted padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(25),
        ), // Curved bottom
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row (Placeholder)
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
                  Text(
                    'كيف حالك اليوم؟', // Placeholder greeting
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
              const CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white54,
                child: Icon(
                  Icons.person_outline,
                  size: 30,
                  color: Colors.white,
                ), // Placeholder avatar
              ),
            ],
          ),
          const SizedBox(height: 20.0),
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
                horizontal: 16.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25.0), // Fully rounded
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade500),
                  const SizedBox(width: 10.0),
                  Text(
                    'ابحث عن دواء...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
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
        top: 16.0,
        bottom: 8.0,
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
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    // Placeholder categories - replace with actual data later
    final categories = [
      {'name': 'مضادات الالتهاب', 'icon': Icons.local_pharmacy_outlined},
      {'name': 'علاج الألم', 'icon': Icons.healing_outlined},
      {'name': 'نزلات البرد', 'icon': Icons.ac_unit_outlined},
      {'name': 'العناية بالبشرة', 'icon': Icons.spa_outlined},
      {
        'name': 'فيتامينات',
        'icon': Icons.health_and_safety_outlined,
      }, // Added more examples
      {'name': 'مضادات حيوية', 'icon': Icons.medication_liquid_outlined},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 110, // Adjusted height
      child: ListView.separated(
        // Use ListView for horizontal scroll
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12.0),
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () {
              // Use setCategory method
              context.read<MedicineProvider>().setCategory(
                category['name'] as String? ?? '',
              ); // Corrected call
              // Optionally navigate or just filter the main list
              print("Category Tapped: ${category['name']}");
            },
            borderRadius: BorderRadius.circular(10.0),
            child: Container(
              width: 90, // Fixed width for category items
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28, // Slightly smaller avatar
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.7),
                    child: Icon(
                      category['icon'] as IconData?,
                      size: 26,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    category['name'] as String? ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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
      height: 180, // Increased height to accommodate DrugListItem better
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: drugs.length,
        padding: const EdgeInsets.symmetric(
          horizontal: 12.0,
        ), // Padding for list ends
        itemBuilder: (context, index) {
          final drug = drugs[index];
          return SizedBox(
            // Constrain width of items in horizontal list
            width: 160, // Adjust width for card-like appearance
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
        final int crossAxisCount =
            useGridView
                ? (constraints.maxWidth / 220).floor().clamp(2, 4)
                : 1; // Adjust item width estimate

        if (useGridView) {
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio:
                  2.2, // Adjust aspect ratio for grid items with image
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
