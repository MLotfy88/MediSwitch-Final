import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart';
import '../bloc/medicine_provider.dart'; // Use MedicineProvider to access search use case

// TODO: Refine search logic and UI
class DrugSearchDelegate extends SearchDelegate<DrugEntity?> {
  // Return selected DrugEntity or null

  // Use buildActions to add actions to the AppBar (e.g., clear query button)
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = ''; // Clear the search query
          showSuggestions(context); // Show suggestions again after clearing
        },
      ),
    ];
  }

  // Use buildLeading to add a leading widget to the AppBar (e.g., back button)
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Close the search delegate, returning null
      },
    );
  }

  // Use buildResults to show results based on the query after submission (e.g., pressing Enter)
  @override
  Widget buildResults(BuildContext context) {
    // Trigger search using the provider's search method
    // We might need a dedicated search method in MedicineProvider or DoseCalculatorProvider
    // For now, let's reuse MedicineProvider's search logic
    // Note: This might load all drugs if query is empty initially, consider handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use read here as we are triggering an action, not just watching state
      // Ensure MedicineProvider is accessible in this context
      // Might need to pass the provider or use cases directly if not available via context
      try {
        context.read<MedicineProvider>().setSearchQuery(query);
      } catch (e) {
        print(
          "Error: MedicineProvider not found in DrugSearchDelegate context. Ensure it's provided higher up.",
        );
        // Handle error appropriately, maybe show a message
      }
    });

    // Display the results from the provider
    return Consumer<MedicineProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (provider.error.isNotEmpty) {
          return Center(child: Text('خطأ: ${provider.error}'));
        }
        final results =
            provider.filteredMedicines; // Use filtered results based on query
        if (results.isEmpty) {
          return const Center(child: Text('لا توجد نتائج'));
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final drug = results[index];
            return ListTile(
              title: Text(drug.tradeName),
              subtitle: Text(drug.arabicName),
              onTap: () {
                close(
                  context,
                  drug,
                ); // Close search and return the selected drug
              },
            );
          },
        );
      },
    );
  }

  // Use buildSuggestions to show suggestions as the user types
  @override
  Widget buildSuggestions(BuildContext context) {
    // Optionally implement suggestions based on the query
    // For simplicity, we can show the same results view as suggestions
    // Or implement a different suggestion logic (e.g., recent searches)
    // Let's reuse buildResults for now
    return buildResults(context);
  }

  // Optional: Customize the search field theme
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor:
            theme.scaffoldBackgroundColor, // Match scaffold background
        elevation: 0, // No shadow
        iconTheme: theme.iconTheme,
        titleTextStyle: theme.textTheme.titleLarge,
        toolbarTextStyle: theme.textTheme.bodyMedium,
      ),
      inputDecorationTheme:
          searchFieldDecorationTheme ??
          InputDecorationTheme(
            hintStyle: searchFieldStyle ?? theme.inputDecorationTheme.hintStyle,
            border: InputBorder.none,
          ),
    );
  }
}
