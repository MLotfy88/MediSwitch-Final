import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll; // Add optional callback for "View All"
  final Widget? action; // Keep optional action widget
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.action, // Keep action
    this.padding = const EdgeInsets.only(
      left: 16.0,
      right: 16.0,
      top: 20.0, // Default top padding
      bottom: 12.0, // Default bottom padding
    ),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations instance
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
        children: [
          // Use Flexible to prevent title overflow if action is present
          Flexible(
            child: Text(
              title,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                // Optionally use primary color like in SettingsScreen?
                // color: colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis, // Handle long titles
            ),
          ),
          // Show either the custom action OR the "View All" button
          if (action != null)
            action!
          else if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.viewAll, // Use localized string
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
