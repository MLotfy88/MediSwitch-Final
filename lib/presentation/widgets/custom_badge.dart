import 'package:flutter/material.dart';

class CustomBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const CustomBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.iconSize = 12.0, // Default icon size
    this.padding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 3,
    ), // Default padding
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determine colors based on theme if not provided
    final effectiveBackgroundColor =
        backgroundColor ?? colorScheme.secondaryContainer;
    final effectiveTextColor = textColor ?? colorScheme.onSecondaryContainer;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Take minimum space needed
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: effectiveTextColor),
            const SizedBox(width: 4), // Space between icon and text
          ],
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              // Use labelSmall for text-xs equivalent
              color: effectiveTextColor,
              fontWeight: FontWeight.w500, // font-medium
            ),
          ),
        ],
      ),
    );
  }
}
