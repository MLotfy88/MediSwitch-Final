import 'dart:async'; // Import Timer for debounce
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart'; // Use DrugEntity
import '../bloc/alternatives_provider.dart'; // Import AlternativesProvider
import '../bloc/medicine_provider.dart'; // Corrected provider path
import '../screens/alternatives_screen.dart'; // Import AlternativesScreen
import '../widgets/filter_bottom_sheet.dart'; // Import the bottom sheet widget
import '../../main.dart'; // Import MyApp to access findDrugAlternativesUseCase (temporary DI)
import '../../domain/usecases/find_drug_alternatives.dart'; // Import use case for provider creation
import 'search_screen.dart'; // Import the new SearchScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = '';
  Timer? _debounce; // Timer for search debounce

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use watch for continuous listening, or select for specific properties
    final medicineProvider = context.watch<MedicineProvider>();
    final medicines =
        medicineProvider.filteredMedicines; // Now List<DrugEntity>
    final isLoading = medicineProvider.isLoading;
    final error = medicineProvider.error;
    final categories = medicineProvider.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MediSwitch'),
        centerTitle: true,
        actions: [
          // Add Filter Button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Open the FilterBottomSheet
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Allows sheet to take up more height
                // Use the MedicineProvider from the current context
                builder:
                    (_) => ChangeNotifierProvider.value(
                      value: context.read<MedicineProvider>(),
                      child: const FilterBottomSheet(),
                    ),
              );
            },
            tooltip: 'فلترة حسب الفئة',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                isLoading
                    ? null
                    : () {
                      // Disable while loading
                      medicineProvider.loadInitialData(); // Use renamed method
                    },
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: Column(
        children: [
          // Non-interactive Search Bar - Navigates to SearchScreen
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              // Make the area tappable
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Theme.of(context).hintColor),
                    const SizedBox(width: 8.0),
                    Text(
                      'بحث عن دواء...', // Placeholder text
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // --- Optional Sections (Task 3.1.6) ---
          // Placeholder for "Recently Updated" section
          // Only show if not loading, no error, and search/filter is not active
          if (!isLoading &&
              error.isEmpty &&
              _searchController.text.isEmpty &&
              _selectedCategory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أدوية محدثة مؤخراً', // "Recently Updated Drugs"
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8.0),
                  // Display horizontal list of recently updated drugs
                  SizedBox(
                    height: 50, // Adjust height as needed
                    child:
                        medicineProvider.recentlyUpdatedMedicines.isEmpty
                            ? const Center(
                              child: Text(
                                'لا توجد أدوية محدثة مؤخراً.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                            : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  medicineProvider
                                      .recentlyUpdatedMedicines
                                      .length,
                              itemBuilder: (context, index) {
                                final drug =
                                    medicineProvider
                                        .recentlyUpdatedMedicines[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: ActionChip(
                                    avatar: CircleAvatar(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.1),
                                      child: Text(
                                        drug.tradeName.isNotEmpty
                                            ? drug.tradeName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    label: Text(drug.tradeName),
                                    tooltip: 'عرض تفاصيل ${drug.tradeName}',
                                    onPressed: () {
                                      _showMedicineDetails(context, drug);
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                  const SizedBox(height: 16.0), // Spacing before main list
                ],
              ),
            ),

          // --- Main Medicine List ---
          // Loading/Error Indicator OR Medicine List
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (error.isNotEmpty)
            // Display prominent error message, especially for initial load failures
            Expanded(
              // Use Expanded to take remaining space
              child: Center(
                // Center the error message
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    // Use Column for icon + text + button
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons
                            .error_outline, // Or Icons.cloud_off for network issues
                        color: Colors.red[700],
                        size: 48.0,
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        error, // Display the error message from provider
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 16.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16.0),
                      // Add a retry button
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        onPressed:
                            () =>
                                context
                                    .read<MedicineProvider>()
                                    .loadInitialData(),
                      ),
                    ],
                  ),
                ),
              ),
            )
          // Medicine List (now inside the else block)
          else
            Expanded(
              // Use LayoutBuilder for responsiveness (Task 3.1.7)
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Define breakpoint for switching to GridView
                  const double gridBreakpoint = 600.0;
                  final bool useGridView =
                      constraints.maxWidth >= gridBreakpoint;

                  // Determine cross axis count for GridView
                  final int crossAxisCount =
                      useGridView
                          ? (constraints.maxWidth / 250).floor().clamp(2, 4)
                          : 1; // Adjust item width (250) as needed

                  if (medicines.isEmpty &&
                      _searchController.text.isEmpty &&
                      _selectedCategory.isEmpty) {
                    // Show specific message if list is empty *before* any search/filter
                    return const Center(
                      child: Text('لا توجد بيانات أدوية لعرضها.'),
                    );
                  } else if (medicines.isEmpty) {
                    // Show "no results" only if search/filter is active
                    return const Center(
                      child: Text('لا توجد أدوية متطابقة مع البحث'),
                    );
                  } else if (useGridView) {
                    // Use GridView for wider screens
                    return GridView.builder(
                      padding: const EdgeInsets.all(
                        8.0,
                      ), // Add padding around grid
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 2.8, // Adjust aspect ratio as needed
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: medicines.length,
                      itemBuilder: (context, index) {
                        final drug = medicines[index];
                        return _DrugListItem(
                          drug: drug,
                          onTap: () => _showMedicineDetails(context, drug),
                        );
                      },
                    );
                  } else {
                    // Use ListView for narrower screens
                    return ListView.builder(
                      itemCount: medicines.length,
                      itemBuilder: (context, index) {
                        final drug = medicines[index];
                        return _DrugListItem(
                          drug: drug,
                          onTap: () => _showMedicineDetails(context, drug),
                        );
                      },
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  // Show details using DrugEntity
  void _showMedicineDetails(BuildContext context, DrugEntity drug) {
    // Changed type to DrugEntity
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      // Provide FindDrugAlternativesUseCase to the builder context
      // This requires access to the use case instance, assuming it's available via MyApp
      builder: (builderContext) {
        // Use a different context name
        final findAlternativesUseCase =
            Provider.of<MyApp>(
              context,
              listen: false,
            ).findDrugAlternativesUseCase; // Temporary access via MyApp context
        return Container(
          padding: const EdgeInsets.all(16.0),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  drug.tradeName, // Use DrugEntity field
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  drug.arabicName, // Use DrugEntity field
                  style: const TextStyle(fontSize: 18.0),
                ),
                const Divider(),
                _buildDetailRow(
                  'السعر الحالي',
                  '${drug.price} جنيه',
                ), // Use DrugEntity field
                _buildDetailRow(
                  'الفئة الرئيسية',
                  drug.mainCategory,
                ), // Use DrugEntity field
                // Display additional details
                _buildDetailRow('المادة الفعالة', drug.active),
                _buildDetailRow('الشركة', drug.company),
                _buildDetailRow('الشكل الصيدلي', drug.dosageForm),
                _buildDetailRow('الوحدة', drug.unit),
                _buildDetailRow('الاستخدام', drug.usage),
                _buildDetailRow('الوصف', drug.description),
                _buildDetailRow('آخر تحديث للسعر', drug.lastPriceUpdate),
                const SizedBox(height: 16),
                // Add "Find Alternatives" Button (Task 3.2.9)
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sync_alt),
                    label: const Text('إيجاد البدائل'),
                    onPressed: () {
                      Navigator.pop(
                        builderContext,
                      ); // Close the bottom sheet first using builderContext
                      Navigator.push(
                        context, // Use the original context for navigation
                        MaterialPageRoute(
                          builder:
                              (_) => ChangeNotifierProvider(
                                // Use the use case obtained earlier
                                create:
                                    (_) => AlternativesProvider(
                                      findDrugAlternativesUseCase:
                                          findAlternativesUseCase,
                                    ),
                                child: AlternativesScreen(originalDrug: drug),
                              ),
                        ),
                      );
                    },
                  ),
                ),
                // Add Favorite Button (Premium - Task 3.2.10)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0), // Add some space
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.favorite_border,
                        size: 18,
                      ), // Or Icons.favorite if favorited
                      label: const Text('إضافة للمفضلة (Premium)'),
                      onPressed: null, // Disabled for now
                      // onPressed: () {
                      //   // TODO: Implement Premium check and favorite logic
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     const SnackBar(content: Text('ميزة المفضلة متاحة في الإصدار المدفوع.')),
                      //   );
                      // },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                        foregroundColor: Colors.red.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8), // Bottom padding
              ], // Closing children list for Column
            ), // Closing Column
          ), // Closing SingleChildScrollView
        ); // Closing Container
      }, // Closing builder
    ); // Closing showModalBottomSheet
  } // Closing _showMedicineDetails

  // Helper to build detail row (unchanged)
  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
} // Closing State class

// Helper widget for displaying a drug item in the list/grid
class _DrugListItem extends StatelessWidget {
  final DrugEntity drug;
  final VoidCallback onTap;

  const _DrugListItem({required this.drug, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 8.0, // Adjusted margin for grid/list flexibility
        vertical: 6.0,
      ),
      child: ListTile(
        title: Text(
          drug.tradeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1, // Prevent long names from wrapping excessively
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
          children: [
            Text(drug.arabicName, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2.0),
            Text(
              'السعر: ${drug.price} جنيه',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (drug.mainCategory.isNotEmpty)
              Text(
                'الفئة: ${drug.mainCategory}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isThreeLine: false, // Let subtitle height be dynamic
        onTap: onTap,
      ),
    );
  }
}
