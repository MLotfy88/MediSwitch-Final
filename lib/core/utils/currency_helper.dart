import 'package:flutter/material.dart';

/// Helper class for currency-related utilities
class CurrencyHelper {
  /// Returns the appropriate currency symbol based on locale
  /// Arabic: "ج.م"
  /// English/Other: "L.E"
  static String getCurrencySymbol(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ar' ? 'ج.م' : 'L.E';
  }

  /// Formats a price with the appropriate currency symbol
  static String formatPriceWithCurrency(
    BuildContext context,
    double price, {
    bool includeDecimals = true,
  }) {
    final currencySymbol = getCurrencySymbol(context);
    final formattedPrice =
        includeDecimals ? price.toStringAsFixed(2) : price.toStringAsFixed(0);
    return '$formattedPrice $currencySymbol';
  }
}
