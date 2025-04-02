import 'dart:async'; // Import Timer for debounce
import 'package:flutter/material.dart'; // Keep only one material import
import 'package:provider/provider.dart';
import '../bloc/medicine_provider.dart';
import '../../domain/entities/drug_entity.dart';
import '../widgets/drug_list_item.dart'; // Import the extracted widget
// Removed imports related to _showMedicineDetails

// TODO: Implement SearchProvider/Bloc (Task 3.2.2) if needed

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // Timer for search debounce

  @override
  void initState() {
    super.initState();
    // Initialize search controller with current query from provider
    // Use addPostFrameCallback to ensure provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if mounted before accessing context
        _searchController.text = context.read<MedicineProvider>().searchQuery;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch MedicineProvider for changes in filtered list, loading state, etc.
    final medicineProvider = context.watch<MedicineProvider>();
    final medicines = medicineProvider.filteredMedicines;
    final isLoading =
        medicineProvider.isLoading; // Use loading state for feedback
    final error = medicineProvider.error; // Use error state for feedback

    return Scaffold(
      appBar: AppBar(
        // Implement Search TextField in AppBar (Task 3.2.1)
        title: TextField(
          controller: _searchController,
          autofocus: true, // Focus the search field immediately
          decoration: InputDecoration(
            hintText: 'بحث عن دواء...', // Search hint
            border: InputBorder.none, // Remove the border
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
          ),
          style: TextStyle(
            // Ensure text color matches AppBar theme
            color:
                Theme.of(context).appBarTheme.titleTextStyle?.color ??
                Theme.of(context).colorScheme.onPrimary,
            fontSize: Theme.of(context).appBarTheme.titleTextStyle?.fontSize,
          ),
          onChanged: (value) {
            // Debounce logic
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              // Shorter debounce for search screen
              if (mounted) {
                context.read<MedicineProvider>().setSearchQuery(value);
              }
            });
          },
        ),
        actions: [
          // Clear button
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'مسح البحث',
            onPressed: () {
              _searchController.clear();
              context.read<MedicineProvider>().setSearchQuery('');
            },
          ),
          // TODO: Add Filter button if needed here
        ],
      ),
      body: Column(
        children: [
          // TODO: Add category filters here? Or keep them in HomeScreen/BottomSheet?
          // Display Loading/Error/Results
          if (isLoading &&
              medicines.isEmpty) // Show loading only if list is empty initially
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (error.isNotEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(error, style: const TextStyle(color: Colors.red)),
                ),
              ),
            )
          else if (medicines.isEmpty && _searchController.text.isNotEmpty)
            const Expanded(
              child: Center(child: Text('لا توجد نتائج مطابقة لبحثك.')),
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
                          ? (constraints.maxWidth / 250).floor().clamp(2, 4)
                          : 1;

                  if (useGridView) {
                    return GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 2.8,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: medicines.length,
                      itemBuilder: (context, index) {
                        final drug = medicines[index];
                        // TODO: Refactor _showMedicineDetails to avoid dependency on HomeScreen state methods
                        // For now, we might need to pass the context differently or lift state.
                        // Using a temporary placeholder action.
                        // Use the imported DrugListItem widget
                        return DrugListItem(
                          drug: drug,
                          // Temporary placeholder action
                          onTap: () => print('Tapped ${drug.tradeName}'),
                        );
                      },
                    );
                  } else {
                    // Use ListView for narrower screens
                    return ListView.builder(
                      itemCount: medicines.length,
                      itemBuilder: (context, index) {
                        final drug = medicines[index];
                        // Use the imported DrugListItem widget
                        return DrugListItem(
                          drug: drug,
                          // Temporary placeholder action
                          onTap: () => print('Tapped ${drug.tradeName}'),
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
