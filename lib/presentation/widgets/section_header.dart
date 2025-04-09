import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action; // Optional action widget (e.g., TextButton)
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding = const EdgeInsets.only(
      left: 16.0,
      right: 16.0,
      top: 20.0, // Default top padding
      bottom: 12.0, // Default bottom padding
    ),
  });

  @override
  Widget build(BuildContext context) {
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
          if (action != null) ...[
            const SizedBox(width: 8), // Add space if action exists
            action!,
          ],
        ],
      ),
    );
  }
}
