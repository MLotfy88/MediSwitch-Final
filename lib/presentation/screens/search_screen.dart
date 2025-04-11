import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../bloc/medicine_provider.dart';
// import '../widgets/drug_list_item.dart'; // Replaced by DrugCard
import '../widgets/drug_card.dart'; // Import DrugCard
import 'drug_details_screen.dart'; // Import details screen for navigation
import '../widgets/filter_bottom_sheet.dart'; // Import filter bottom sheet

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchController.text = context.read<MedicineProvider>().searchQuery;
        // Trigger initial search if query exists from previous state
        if (_searchController.text.isNotEmpty) {
          context.read<MedicineProvider>().setSearchQuery(
            _searchController.text,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<MedicineProvider>().setSearchQuery(query);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    if (mounted) {
      context.read<MedicineProvider>().setSearchQuery('');
    }
  }

  void _openFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Important for DraggableScrollableSheet
      backgroundColor: Colors.transparent, // Make background transparent
      builder:
          (_) => ChangeNotifierProvider.value(
            value: context.read<MedicineProvider>(),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6, // Start at 60% height
              minChildSize: 0.3, // Allow shrinking to 30%
              maxChildSize: 0.9, // Allow expanding to 90%
              expand: false, // Prevent full screen expansion by default
              builder: (_, scrollController) {
                // Pass the scrollController to the FilterBottomSheet
                // FilterBottomSheet needs to be adapted to use this controller
                // For now, we wrap it in a container for styling
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24.0),
                    ),
                  ),
                  // Pass the scrollController to FilterBottomSheet
                  child: FilterBottomSheet(scrollController: scrollController),
                );
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicineProvider = context.watch<MedicineProvider>();
    final medicines = medicineProvider.filteredMedicines;
    final isLoading = medicineProvider.isLoading;
    final error = medicineProvider.error;

    return Scaffold(
      appBar: AppBar(
        // Custom AppBar matching the prototype
        leading: IconButton(
          // Back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          // Search input container
          height: 40, // Adjust height as needed
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20), // Rounded corners
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'ابحث عن دواء...',
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).hintColor,
              ),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        color: Theme.of(context).hintColor,
                        onPressed: _clearSearch,
                      )
                      : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10.0,
              ), // Adjust padding
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            onChanged: _onSearchChanged,
          ),
        ),
        actions: [
          IconButton(
            // Filter button
            icon: const Icon(Icons.filter_list),
            tooltip: 'تصفية النتائج',
            onPressed: _openFilterModal,
          ),
        ],
        backgroundColor:
            Theme.of(
              context,
            ).colorScheme.primary, // Match prototype AppBar color
        foregroundColor:
            Theme.of(
              context,
            ).colorScheme.onPrimary, // Ensure icons/text are visible
      ),
      body: Column(
        children: [
          // Display Loading/Error/Results
          if (isLoading &&
              medicines.isEmpty) // Show loading only if list is empty initially
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (error.isNotEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            )
          else if (medicines.isEmpty && _searchController.text.isNotEmpty)
            const Expanded(
              child: Center(child: Text('لا توجد نتائج مطابقة لبحثك.')),
            )
          else if (medicines.isEmpty && _searchController.text.isEmpty)
            const Expanded(
              child: Center(
                child: Text('ابدأ البحث عن دواء...'),
              ), // Prompt to start searching
            )
          else
            Expanded(
              // Use LayoutBuilder for responsiveness, similar to HomeScreen
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double gridBreakpoint = 600.0;
                  final bool useGridView =
                      constraints.maxWidth >= gridBreakpoint;
                  final int crossAxisCount =
                      useGridView
                          ? (constraints.maxWidth / 240).floor().clamp(2, 4)
                          : 1; // Adjusted width estimate
                  final double childAspectRatio =
                      useGridView ? 0.85 : 2.8; // Adjust aspect ratio

                  if (useGridView) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: medicines.length,
                      itemBuilder: (context, index) {
                        final drug = medicines[index];
                        // Use DrugCard (detailed) for GridView results
                        return DrugCard(
                          drug: drug,
                          type: DrugCardType.detailed,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => DrugDetailsScreen(drug: drug),
                              ),
                            );
                          },
                        );
                      },
                    );
                  } else {
                    // Use ListView for narrower screens
                    return ListView.builder(
                      itemCount: medicines.length,
                      itemBuilder: (context, index) {
                        final drug = medicines[index];
                        // Use DrugCard (detailed) for ListView results
                        return DrugCard(
                          drug: drug,
                          type: DrugCardType.detailed,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => DrugDetailsScreen(drug: drug),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ), // Closing Expanded for LayoutBuilder result
        ],
      ),
    );
  } // End of build method
} // End of _SearchScreenState class
