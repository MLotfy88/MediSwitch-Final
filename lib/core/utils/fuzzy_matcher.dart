import 'package:dartz/dartz.dart';

/// Fuzzy String Matching Utilities for Drug Interaction Detection
class FuzzyMatcher {
  /// Calculate Levenshtein distance between two strings
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;

    // Create matrix
    List<List<int>> matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    // Initialize first column and row
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Calculate distances
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Calculate similarity ratio (0.0 to 1.0)
  static double similarityRatio(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = levenshteinDistance(s1, s2);
    final maxLen = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLen);
  }

  /// Check if two strings are similar (threshold: 0.8 = 80% similarity)
  static bool isSimilar(String s1, String s2, {double threshold = 0.8}) {
    return similarityRatio(s1, s2) >= threshold;
  }

  /// Normalize string for comparison
  static String normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
  }

  /// Find best match from a list of candidates
  static Tuple2<String, double>? findBestMatch(
    String query,
    List<String> candidates, {
    double minThreshold = 0.6,
  }) {
    if (candidates.isEmpty) return null;

    final normalizedQuery = normalize(query);
    String? bestMatch;
    double bestScore = 0.0;

    for (final candidate in candidates) {
      final normalizedCandidate = normalize(candidate);
      final score = similarityRatio(normalizedQuery, normalizedCandidate);

      if (score > bestScore && score >= minThreshold) {
        bestScore = score;
        bestMatch = candidate;
      }
    }

    return bestMatch != null ? Tuple2(bestMatch, bestScore) : null;
  }

  /// Check if query contains candidate (partial match)
  static bool containsMatch(String query, String candidate) {
    final normalizedQuery = normalize(query);
    final normalizedCandidate = normalize(candidate);

    return normalizedQuery.contains(normalizedCandidate) ||
        normalizedCandidate.contains(normalizedQuery);
  }
}
