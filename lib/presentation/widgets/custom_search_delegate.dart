import 'package:flutter/material.dart';
import '../../domain/entities/drug_entity.dart'; // Assuming DrugEntity path
import 'drug_card.dart'; // Import DrugCard

// Basic Search Delegate for selecting a DrugEntity
class CustomSearchDelegate extends SearchDelegate<DrugEntity?> {
  final List<DrugEntity> medicines;
  final List<DrugEntity> Function(String query) searchLogic;
  @override
  final String searchFieldLabel;

  CustomSearchDelegate({
    required this.medicines,
    required this.searchLogic,
    this.searchFieldLabel = 'Search...', // Default label
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    // Actions for AppBar (e.g., clear query button)
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context); // Refresh suggestions
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // Leading icon on the left of the AppBar (e.g., back button)
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null); // Close search, return null
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Show results based on the query (can be same as suggestions)
    final results = searchLogic(query);
    // Pass context to the helper method
    return _buildSuggestionsList(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Show suggestions as the user types
    final suggestions = searchLogic(query);
    // Pass context to the helper method
    return _buildSuggestionsList(context, suggestions);
  }

  // Modified to accept BuildContext
  Widget _buildSuggestionsList(
    BuildContext context,
    List<DrugEntity> suggestions,
  ) {
    if (suggestions.isEmpty && query.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'لم يتم العثور على نتائج مطابقة لـ "$query"',
            textAlign: TextAlign.center,
            // Access Theme using the passed context
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).hintColor),
          ),
        ),
      );
    }
    if (suggestions.isEmpty && query.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'ابدأ بكتابة اسم الدواء أو المادة الفعالة للبحث...',
            textAlign: TextAlign.center,
            // Access Theme using the passed context
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).hintColor),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final drug = suggestions[index];
        // Use DrugCard for displaying suggestions/results
        // Using thumbnail type for compactness in search results
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: DrugCard(
            // Uses kCategoryTranslation internally now
            drug: drug,
            type: DrugCardType.thumbnail, // Use thumbnail for search results
            onTap: () {
              close(context, drug); // Close search, return selected drug
            },
          ),
        );
      },
    );
  }
}
