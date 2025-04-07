import 'dart:async'; // Import Timer for debounce
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/medicine_provider.dart'; // Corrected provider path
import '../widgets/filter_bottom_sheet.dart'; // Import the bottom sheet widget
import 'search_screen.dart'; // Import the new SearchScreen
import 'drug_details_screen.dart'; // Import the new details screen
import '../widgets/drug_list_item.dart'; // Import the list item widget

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
                    .loadInitialData(), // Removed forceRemote parameter
        child: CustomScrollView(
          // Use CustomScrollView for more complex layouts
          slivers: <Widget>[
            // --- Header Section (AppBar replacement) ---
            SliverAppBar(
              // floating: true, // Optional: make it appear on scroll up
              // pinned: true, // Optional: keep it visible
              // snap: true, // Optional: snap effect
              expandedHeight: 180.0, // Adjust height as needed
              backgroundColor:
                  Colors.transparent, // Make background transparent
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(
                  context,
                ), // Use a separate header builder
              ),
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
        top: kToolbarHeight,
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end, // Align content to bottom
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
                  Icons.person,
                  size: 30,
                  color: Colors.white,
                ), // Placeholder avatar
              ),
            ],
          ),
          const SizedBox(height: 16.0),
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
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25.0), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey.shade600),
                  const SizedBox(width: 8.0),
                  Text(
                    'ابحث عن دواء...',
                    style: TextStyle(color: Colors.grey.shade600),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (showViewAll)
            TextButton(onPressed: onVewAllTap, child: const Text('عرض الكل')),
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
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 120, // Adjust height as needed
      child: GridView.builder(
        scrollDirection: Axis.horizontal, // Make categories horizontal
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1, // One row
          mainAxisSpacing: 12.0,
          childAspectRatio: 1.1, // Adjust aspect ratio for horizontal items
        ),
        itemBuilder: (context, index) {
          final category = categories[index];
          return InkWell(
            onTap: () {
              // TODO: Implement category filtering or navigation
              print("Category Tapped: ${category['name']}");
              context.read<MedicineProvider>().setCategory(
                // Use setCategory method
                category['name'] as String? ?? '',
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.5),
                  child: Icon(
                    category['icon'] as IconData?,
                    size: 28,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  category['name'] as String? ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalDrugList(
    BuildContext context,
    List<DrugEntity> drugs,
  ) {
    return SizedBox(
      height: 150, // Adjust height for DrugListItem
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
            width: 180, // Adjust width as needed
            child: DrugListItem(
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
                : 1; // Adjust item width (220)

        if (useGridView) {
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 2.0, // Adjust aspect ratio for grid items
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
            Icon(Icons.error_outline, color: Colors.red[700], size: 48.0),
            const SizedBox(height: 16.0),
            Text(
              error,
              style: TextStyle(color: Colors.red[700], fontSize: 16.0),
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
