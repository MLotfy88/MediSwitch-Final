import 'package:flutter/widgets.dart';

/// Defines standard spacing values used throughout the application,
/// based on an 8px grid system.
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  // Base values (adjust multiplier as needed)
  static const double _baseUnit = 8.0;

  // Standard spacing values
  static const double xxsmall = 0.25 * _baseUnit; // 2.0
  static const double xsmall = 0.5 * _baseUnit; // 4.0
  static const double small = 1.0 * _baseUnit; // 8.0
  static const double medium = 1.5 * _baseUnit; // 12.0
  static const double large = 2.0 * _baseUnit; // 16.0
  static const double xlarge = 3.0 * _baseUnit; // 24.0
  static const double xxlarge = 4.0 * _baseUnit; // 32.0

  // --- EdgeInsets ---

  // All
  static const EdgeInsets edgeInsetsAllZero = EdgeInsets.zero;
  static const EdgeInsets edgeInsetsAllXSmall = EdgeInsets.all(xsmall);
  static const EdgeInsets edgeInsetsAllSmall = EdgeInsets.all(small);
  static const EdgeInsets edgeInsetsAllMedium = EdgeInsets.all(medium);
  static const EdgeInsets edgeInsetsAllLarge = EdgeInsets.all(large);
  static const EdgeInsets edgeInsetsAllXLarge = EdgeInsets.all(xlarge);

  // Symmetric Vertical
  static const EdgeInsets edgeInsetsVXXSmall = EdgeInsets.symmetric(
    vertical: xxsmall,
  );
  static const EdgeInsets edgeInsetsVXSmall = EdgeInsets.symmetric(
    vertical: xsmall,
  );
  static const EdgeInsets edgeInsetsVSmall = EdgeInsets.symmetric(
    vertical: small,
  );
  static const EdgeInsets edgeInsetsVMedium = EdgeInsets.symmetric(
    vertical: medium,
  );
  static const EdgeInsets edgeInsetsVLarge = EdgeInsets.symmetric(
    vertical: large,
  );
  static const EdgeInsets edgeInsetsVXLarge = EdgeInsets.symmetric(
    vertical: xlarge,
  );

  // Symmetric Horizontal
  static const EdgeInsets edgeInsetsHXXSmall = EdgeInsets.symmetric(
    horizontal: xxsmall,
  );
  static const EdgeInsets edgeInsetsHXSmall = EdgeInsets.symmetric(
    horizontal: xsmall,
  );
  static const EdgeInsets edgeInsetsHSmall = EdgeInsets.symmetric(
    horizontal: small,
  );
  static const EdgeInsets edgeInsetsHMedium = EdgeInsets.symmetric(
    horizontal: medium,
  );
  static const EdgeInsets edgeInsetsHLarge = EdgeInsets.symmetric(
    horizontal: large,
  );
  static const EdgeInsets edgeInsetsHXLarge = EdgeInsets.symmetric(
    horizontal: xlarge,
  );

  // --- SizedBox ---

  // Vertical Gaps
  static const SizedBox gapVXXSmall = SizedBox(height: xxsmall);
  static const SizedBox gapVXSmall = SizedBox(height: xsmall);
  static const SizedBox gapVSmall = SizedBox(height: small);
  static const SizedBox gapVMedium = SizedBox(height: medium);
  static const SizedBox gapVLarge = SizedBox(height: large);
  static const SizedBox gapVXLarge = SizedBox(height: xlarge);
  static const SizedBox gapVXXLarge = SizedBox(height: xxlarge);

  // Horizontal Gaps
  static const SizedBox gapHXXSmall = SizedBox(width: xxsmall);
  static const SizedBox gapHXSmall = SizedBox(width: xsmall);
  static const SizedBox gapHSmall = SizedBox(width: small);
  static const SizedBox gapHMedium = SizedBox(width: medium);
  static const SizedBox gapHLarge = SizedBox(width: large);
  static const SizedBox gapHXLarge = SizedBox(width: xlarge);
  static const SizedBox gapHXXLarge = SizedBox(width: xxlarge);

  // --- Padding Widgets ---
  // Convenience widgets for common padding scenarios

  static Padding paddingAllSmall(Widget child) =>
      Padding(padding: edgeInsetsAllSmall, child: child);
  static Padding paddingAllMedium(Widget child) =>
      Padding(padding: edgeInsetsAllMedium, child: child);
  static Padding paddingAllLarge(Widget child) =>
      Padding(padding: edgeInsetsAllLarge, child: child);

  static Padding paddingHorizontalSmall(Widget child) =>
      Padding(padding: edgeInsetsHSmall, child: child);
  static Padding paddingHorizontalMedium(Widget child) =>
      Padding(padding: edgeInsetsHMedium, child: child);
  static Padding paddingHorizontalLarge(Widget child) =>
      Padding(padding: edgeInsetsHLarge, child: child);

  static Padding paddingVerticalSmall(Widget child) =>
      Padding(padding: edgeInsetsVSmall, child: child);
  static Padding paddingVerticalMedium(Widget child) =>
      Padding(padding: edgeInsetsVMedium, child: child);
  static Padding paddingVerticalLarge(Widget child) =>
      Padding(padding: edgeInsetsVLarge, child: child);
}
