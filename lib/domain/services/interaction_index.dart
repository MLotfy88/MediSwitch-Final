import '../../domain/entities/drug_interaction.dart';

/// Search Index for fast drug interaction lookups
class InteractionIndex {
  // Index: ingredient/drug name -> list of interaction indices
  final Map<String, Set<int>> _ingredientIndex = {};

  // Store all interactions
  final List<DrugInteraction> _allInteractions = [];

  // Track if index is built
  bool _isBuilt = false;

  /// Build index from interactions list
  void buildIndex(List<DrugInteraction> interactions) {
    if (_isBuilt) return;

    _allInteractions.clear();
    _ingredientIndex.clear();

    for (int i = 0; i < interactions.length; i++) {
      _allInteractions.add(interactions[i]);

      final interaction = interactions[i];

      // Index ingredient1
      final ing1 = interaction.ingredient1.toLowerCase().trim();
      _ingredientIndex.putIfAbsent(ing1, () => {}).add(i);

      // Index ingredient2 if not "multiple"
      final ing2 = interaction.ingredient2.toLowerCase().trim();
      if (ing2 != 'multiple' && ing2 != 'unknown') {
        _ingredientIndex.putIfAbsent(ing2, () => {}).add(i);
      }

      // Also index individual words for partial matching
      for (final word in ing1.split(RegExp(r'\s+'))) {
        if (word.length > 2) {
          _ingredientIndex.putIfAbsent(word, () => {}).add(i);
        }
      }
    }

    _isBuilt = true;
  }

  /// Find interactions by ingredient/drug name
  List<DrugInteraction> findByIngredient(String ingredient) {
    if (!_isBuilt) return [];

    final normalized = ingredient.toLowerCase().trim();
    final indices = _ingredientIndex[normalized];

    if (indices == null) return [];

    return indices.map((i) => _allInteractions[i]).toList();
  }

  /// Find interactions by multiple ingredients (OR logic)
  List<DrugInteraction> findByAnyIngredient(List<String> ingredients) {
    if (!_isBuilt || ingredients.isEmpty) return [];

    final Set<int> allIndices = {};

    for (final ingredient in ingredients) {
      final normalized = ingredient.toLowerCase().trim();
      final indices = _ingredientIndex[normalized];
      if (indices != null) {
        allIndices.addAll(indices);
      }
    }

    return allIndices.map((i) => _allInteractions[i]).toList();
  }

  /// Get all indexed ingredients
  List<String> get allIndexedIngredients => _ingredientIndex.keys.toList();

  /// Get total interactions count
  int get totalInteractions => _allInteractions.length;

  /// Clear index
  void clear() {
    _ingredientIndex.clear();
    _allInteractions.clear();
    _isBuilt = false;
  }
}
