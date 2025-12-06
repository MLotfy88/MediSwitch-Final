import 'package:flutter/material.dart';

/// App-wide spacing constants
/// Matches TailwindCSS spacing scale
class AppSpacing {
  AppSpacing._();

  // Base unit: 4px
  static const double unit = 4.0;

  // Spacing scale (matches Tailwind)
  static const double xs = unit; // 4px - space-1
  static const double sm = unit * 2; // 8px - space-2
  static const double md = unit * 3; // 12px - space-3
  static const double lg = unit * 4; // 16px - space-4
  static const double xl = unit * 5; // 20px - space-5
  static const double xl2 = unit * 6; // 24px - space-6
  static const double xl3 = unit * 8; // 32px - space-8
  static const double xl4 = unit * 10; // 40px - space-10
  static const double xl5 = unit * 12; // 48px - space-12
  static const double xl6 = unit * 16; // 64px - space-16

  // Common paddings
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  static const EdgeInsets paddingXL2 = EdgeInsets.all(xl2);

  // Horizontal paddings
  static const EdgeInsets paddingHorizontalSM = EdgeInsets.symmetric(
    horizontal: sm,
  );
  static const EdgeInsets paddingHorizontalMD = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets paddingHorizontalLG = EdgeInsets.symmetric(
    horizontal: lg,
  );
  static const EdgeInsets paddingHorizontalXL = EdgeInsets.symmetric(
    horizontal: xl,
  );

  // Vertical paddings
  static const EdgeInsets paddingVerticalSM = EdgeInsets.symmetric(
    vertical: sm,
  );
  static const EdgeInsets paddingVerticalMD = EdgeInsets.symmetric(
    vertical: md,
  );
  static const EdgeInsets paddingVerticalLG = EdgeInsets.symmetric(
    vertical: lg,
  );
  static const EdgeInsets paddingVerticalXL = EdgeInsets.symmetric(
    vertical: xl,
  );

  // Screen paddings
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: lg,
  );
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(
    vertical: lg,
  );

  // Card paddings
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(md);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(xl);
}

/// App-wide border radius constants
/// Matches TailwindCSS rounded scale
class AppRadius {
  AppRadius._();

  // Border radius values (matches Tailwind + design-refresh)
  static const double none = 0;
  static const double sm = 6; // rounded-sm
  static const double md = 8; // rounded-md (default)
  static const double DEFAULT = md; // rounded (8px)
  static const double lg = 12; // rounded-lg (used frequently)
  static const double xl = 14; // rounded-xl
  static const double xl2 = 16; // rounded-2xl
  static const double xl3 = 20; // rounded-3xl
  static const double full = 9999; // rounded-full

  // BorderRadius objects
  static BorderRadius get circular => BorderRadius.circular(DEFAULT);
  static BorderRadius get circularSm => BorderRadius.circular(sm);
  static BorderRadius get circularMd => BorderRadius.circular(md);
  static BorderRadius get circularLg => BorderRadius.circular(lg);
  static BorderRadius get circularXl => BorderRadius.circular(xl);
  static BorderRadius get circularXl2 => BorderRadius.circular(xl2);
  static BorderRadius get circularXl3 => BorderRadius.circular(xl3);
  static BorderRadius get circularFull => BorderRadius.circular(full);

  // Common shapes
  static RoundedRectangleBorder get shapeSm =>
      RoundedRectangleBorder(borderRadius: circularSm);
  static RoundedRectangleBorder get shapeMd =>
      RoundedRectangleBorder(borderRadius: circularMd);
  static RoundedRectangleBorder get shapeLg =>
      RoundedRectangleBorder(borderRadius: circularLg);
  static RoundedRectangleBorder get shapeXl =>
      RoundedRectangleBorder(borderRadius: circularXl);
  static RoundedRectangleBorder get shapeXl2 =>
      RoundedRectangleBorder(borderRadius: circularXl2);
}

/// App-wide shadow constants
class AppShadows {
  AppShadows._();

  // Shadow definitions
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Card shadow
  static List<BoxShadow> get card => md;
}

/// App-wide transition durations
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration slower = Duration(milliseconds: 400);
}

/// App-wide curves
class AppCurves {
  AppCurves._();

  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve spring = Curves.elasticOut;
}
