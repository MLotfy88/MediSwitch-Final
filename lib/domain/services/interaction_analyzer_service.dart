import 'package:flutter/foundation.dart'; // For @immutable
import '../entities/drug_interaction.dart';
import '../entities/interaction_severity.dart';

/// Service to analyze multi-drug interactions using graph algorithms.
class MultiDrugInteractionAnalyzer {
  // ID for current node to optimize graph algorithms
  static int _nextId = 0;

  /// Analyzes interactions between a list of medicines.
  ///
  /// Returns a map containing:
  /// - pairwise_interactions: Direct interactions between pairs
  /// - interaction_paths: Indirect interaction paths (A->B->C)
  /// - overall_severity: The highest severity found
  /// - requires_attention: Boolean indicating if severity is moderate or higher
  /// - recommendations: List of actionable recommendations
  static Map<String, dynamic> analyzeInteractions(
    List<String> medicineNames,
    List<Map<String, dynamic>> pairwiseInteractions,
  ) {
    // Reset ID counter
    _nextId = 0;

    // Build interaction graph
    final graph = _buildInteractionGraph(medicineNames, pairwiseInteractions);

    // Find cumulative interaction paths using DFS
    final List<Map<String, dynamic>> paths = _findInteractionPaths(graph);

    // Determine overall severity
    final InteractionSeverity overallSeverity = _calculateOverallSeverity(
      pairwiseInteractions,
    );

    // Generate recommendations
    final recommendations = _generateRecommendations(
      pairwiseInteractions,
      paths,
    );

    return {
      'pairwise_interactions': pairwiseInteractions,
      'interaction_paths': paths,
      'overall_severity': overallSeverity.toString().split('.').last,
      'requires_attention':
          overallSeverity.index >= InteractionSeverity.moderate.index,
      'recommendations': recommendations,
    };
  }

  static Map<String, Map<String, List<DrugInteraction>>> _buildInteractionGraph(
    List<String> medicineNames,
    List<Map<String, dynamic>> pairwiseInteractions,
  ) {
    final Map<String, Map<String, List<DrugInteraction>>> graph = {};

    // Initialize empty map for each medicine
    for (final name in medicineNames) {
      graph[name] = {};
    }

    // Add interactions to graph
    for (final interaction in pairwiseInteractions) {
      final medicine1 = interaction['medicine1'] as String;
      final medicine2 = interaction['medicine2'] as String;
      final interactions = interaction['interactions'] as List<DrugInteraction>;

      // Add interactions in both directions (undirected graph)
      if (!graph[medicine1]!.containsKey(medicine2)) {
        graph[medicine1]![medicine2] = [];
      }
      graph[medicine1]![medicine2]!.addAll(interactions);

      if (!graph[medicine2]!.containsKey(medicine1)) {
        graph[medicine2]![medicine1] = [];
      }
      graph[medicine2]![medicine1]!.addAll(interactions);
    }

    return graph;
  }

  static List<Map<String, dynamic>> _findInteractionPaths(
    Map<String, Map<String, List<DrugInteraction>>> graph,
  ) {
    final List<Map<String, dynamic>> paths = [];
    final Set<String> visited = {};

    final medicines =
        graph.keys.map((name) => _DrugNode(++_nextId, name)).toList();

    for (final startNode in medicines) {
      if (!visited.contains(startNode.name)) {
        final List<_DrugNode> currentPath = [startNode];
        _dfs(graph, startNode, visited, currentPath, paths);
      }
    }

    return paths;
  }

  static void _dfs(
    Map<String, Map<String, List<DrugInteraction>>> graph,
    _DrugNode current,
    Set<String> visited,
    List<_DrugNode> currentPath,
    List<Map<String, dynamic>> paths,
  ) {
    visited.add(current.name);

    for (final neighborName in graph[current.name]!.keys) {
      if (visited.contains(neighborName)) continue;

      final neighbor = _DrugNode(++_nextId, neighborName);
      final interactions = graph[current.name]![neighborName]!;

      if (interactions.isNotEmpty) {
        currentPath.add(neighbor);

        if (currentPath.length >= 3) {
          final List<String> pathNames =
              currentPath.map((node) => node.name).toList();
          final InteractionSeverity pathSeverity = _calculatePathSeverity(
            graph,
            currentPath,
          );

          paths.add({
            'path': pathNames,
            'severity': pathSeverity.toString().split('.').last,
            'description': _generatePathDescription(pathNames, pathSeverity),
          });
        }

        _dfs(graph, neighbor, visited, currentPath, paths);

        currentPath.removeLast();
      }
    }
  }

  static InteractionSeverity _calculatePathSeverity(
    Map<String, Map<String, List<DrugInteraction>>> graph,
    List<_DrugNode> path,
  ) {
    InteractionSeverity maxSeverity = InteractionSeverity.minor;

    for (int i = 0; i < path.length - 1; i++) {
      final drug1 = path[i].name;
      final drug2 = path[i + 1].name;

      final interactions = graph[drug1]![drug2]!;
      for (final interaction in interactions) {
        if (interaction.severity.index > maxSeverity.index) {
          maxSeverity = interaction.severity;
        }
      }
    }

    return maxSeverity;
  }

  static InteractionSeverity _calculateOverallSeverity(
    List<Map<String, dynamic>> pairwiseInteractions,
  ) {
    InteractionSeverity maxSeverity = InteractionSeverity.minor;

    for (final pair in pairwiseInteractions) {
      final interactions = pair['interactions'] as List<DrugInteraction>;
      for (final interaction in interactions) {
        if (interaction.severity.index > maxSeverity.index) {
          maxSeverity = interaction.severity;
        }
      }
    }

    return maxSeverity;
  }

  static String _generatePathDescription(
    List<String> path,
    InteractionSeverity severity,
  ) {
    final severityDesc = _getSeverityDescription(severity);
    return 'تفاعل $severityDesc بين ${path.join(' و ')}';
  }

  static String _getSeverityDescription(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.minor:
        return 'بسيط';
      case InteractionSeverity.moderate:
        return 'متوسط';
      case InteractionSeverity.major:
        return 'كبير';
      case InteractionSeverity.severe:
        return 'شديد';
      case InteractionSeverity.contraindicated:
        return 'مضاد استطباب';
      case InteractionSeverity.unknown:
        return 'غير معروف';
    }
  }

  static List<Map<String, dynamic>> _generateRecommendations(
    List<Map<String, dynamic>> pairwiseInteractions,
    List<Map<String, dynamic>> paths,
  ) {
    final List<Map<String, dynamic>> recommendations = [];

    for (final pair in pairwiseInteractions) {
      final medicine1 = pair['medicine1'] as String;
      final medicine2 = pair['medicine2'] as String;
      final interactions = pair['interactions'] as List<DrugInteraction>;

      final InteractionSeverity maxSeverity = _getHighestSeverity(interactions);

      if (maxSeverity.index >= InteractionSeverity.moderate.index) {
        recommendations.add({
          'type': 'pair',
          'medicines': [medicine1, medicine2],
          'severity': maxSeverity.toString().split('.').last,
          'recommendation': _getRecommendationForSeverity(
            maxSeverity,
            medicine1,
            medicine2,
          ),
        });
      }
    }

    for (final path in paths) {
      final pathMedicines = path['path'] as List<String>;
      final severity = InteractionSeverity.values.firstWhere(
        (s) => s.toString().split('.').last == path['severity'],
        orElse: () => InteractionSeverity.minor,
      );

      if (severity.index >= InteractionSeverity.major.index) {
        recommendations.add({
          'type': 'path',
          'medicines': pathMedicines,
          'severity': severity.toString().split('.').last,
          'recommendation':
              'يجب مراقبة التفاعل التسلسلي بين ${pathMedicines.join(' و ')}',
        });
      }
    }

    return recommendations;
  }

  static InteractionSeverity _getHighestSeverity(
    List<DrugInteraction> interactions,
  ) {
    if (interactions.isEmpty) return InteractionSeverity.minor;
    InteractionSeverity highest = InteractionSeverity.minor;
    for (final interaction in interactions) {
      if (interaction.severity.index > highest.index) {
        highest = interaction.severity;
      }
    }
    return highest;
  }

  static String _getRecommendationForSeverity(
    InteractionSeverity severity,
    String medicine1,
    String medicine2,
  ) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return 'لا يجب استخدام $medicine1 و $medicine2 معًا أبدًا';
      case InteractionSeverity.severe:
        return 'يفضل تجنب استخدام $medicine1 و $medicine2 معًا، والبحث عن بدائل';
      case InteractionSeverity.major:
        return 'يجب مراقبة المريض بعناية عند استخدام $medicine1 و $medicine2 معًا';
      case InteractionSeverity.moderate:
        return 'قد يحتاج المريض لتعديل الجرعة عند استخدام $medicine1 و $medicine2 معًا';
      case InteractionSeverity.minor:
      case InteractionSeverity.unknown:
        return 'مراقبة طبيعية عند استخدام $medicine1 و $medicine2 معًا';
    }
  }
}

@immutable
class _DrugNode {
  final int id;
  final String name;

  const _DrugNode(this.id, this.name);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _DrugNode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
