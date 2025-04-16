import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      // Use tertiary color for background as defined in theme
      color: colorScheme.tertiary,
      // Apply specific height and padding from design doc
      height: 40.0, // h-10
      padding: const EdgeInsets.symmetric(
        horizontal: 4.0,
      ), // px-1 (adjust if p-1 meant all sides)
      // Add bottom border
      decoration: BoxDecoration(
        color: colorScheme.tertiary, // Ensure color is set if using decoration
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline,
            width: 1.0,
          ), // border-b border-border
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo - Adjust padding/size if needed
          Padding(
            padding: const EdgeInsets.only(
              left: 12.0,
            ), // Add some start padding
            child: Image.asset(
              'assets/images/logo.png', // Ensure logo path is correct
              height: 40, // Adjust height slightly within the 40px bar
              // color: colorScheme.onTertiary, // Apply white color if logo is single color
            ),
          ),
          // Notification Button
          IconButton(
            icon: Icon(
              LucideIcons.bell,
              size: 30,
              color: colorScheme.onTertiary,
            ), // h-5 w-5, white
            onPressed: () {
              // TODO: Implement notification logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications (Not Implemented)'),
                ),
              );
            },
            tooltip: 'الإشعارات',
            splashRadius: 20,
            // Add hover effect if needed (e.g., using hoverColor in IconButtonTheme)
          ),
        ],
      ),
    );
  }
}
