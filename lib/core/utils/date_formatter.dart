import 'package:intl/intl.dart';

class DateFormatter {
  /// Formats a date string from ISO 8601 (YYYY-MM-DD) or similar to dd/mm/yyyy.
  /// Returns the original string if parsing fails.
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      // Handle potential formats like YYYY-MM-DD or YYYY/MM/DD
      DateTime? parsedDate;
      if (dateString.contains('-')) {
        parsedDate = DateTime.tryParse(dateString);
      } else if (dateString.contains('/')) {
        // Assume existing format might be different, but for now we expect YYYY-MM-DD from DB
        try {
          final parts = dateString.split('/');
          if (parts.length == 3) {
            // Check if it's already d/m/y or y/m/d?
            // If year is first (4 digits)
            if (parts[0].length == 4) {
              parsedDate = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
            } else {
              // Assume d/m/y
              parsedDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          }
        } catch (e) {
          // ignore
        }
      }

      if (parsedDate != null) {
        return DateFormat('dd/MM/yyyy').format(parsedDate);
      }

      // Attempt generic parse
      final DateTime genericDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(genericDate);
    } catch (e) {
      // If parsing fails, return the original string to avoid showing nothing/error
      return dateString;
    }
  }
}
