import 'package:flutter/material.dart';
import '../../domain/entities/drug_entity.dart'; // Assuming DrugEntity path

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
    return _buildSuggestionsList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Show suggestions as the user types
    final suggestions = searchLogic(query);
    return _buildSuggestionsList(suggestions);
  }

  Widget _buildSuggestionsList(List<DrugEntity> suggestions) {
    if (suggestions.isEmpty && query.isNotEmpty) {
      return const Center(child: Text('لم يتم العثور على نتائج'));
    }
    if (suggestions.isEmpty && query.isEmpty) {
      return const Center(child: Text('ابدأ البحث عن دواء...'));
    }

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final drug = suggestions[index];
        return ListTile(
          title: Text(drug.tradeName),
          subtitle: Text(drug.arabicName),
          onTap: () {
            close(context, drug); // Close search, return selected drug
          },
        );
      },
    );
  }
}
