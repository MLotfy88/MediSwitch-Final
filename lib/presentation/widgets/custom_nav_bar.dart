import 'package:flutter/material.dart';

// Data class for navigation bar items
class NavBarItem {
  final IconData icon;
  final String label;

  const NavBarItem({required this.icon, required this.label});
}

// Custom Navigation Bar Widget
class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<NavBarItem> items;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Use Material 3 NavigationBar for modern look and feel
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onItemSelected,
      // Customize appearance based on theme
      backgroundColor: colorScheme.surface, // Or surfaceContainerLow etc.
      indicatorColor: colorScheme.secondaryContainer, // Indicator color
      height: 65, // Adjust height if needed
      labelBehavior:
          NavigationDestinationLabelBehavior.alwaysShow, // Show labels always
      destinations:
          items.map((item) {
            return NavigationDestination(
              icon: Icon(
                item.icon,
                color: colorScheme.onSurfaceVariant,
              ), // Icon color
              selectedIcon: Icon(
                item.icon,
                color: colorScheme.onSecondaryContainer,
              ), // Selected icon color
              label: item.label,
              // Customize text style if needed using labelTextStyle
              // labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
              //   (Set<MaterialState> states) {
              //     return textTheme.labelSmall!.copyWith(
              //       color: states.contains(MaterialState.selected)
              //           ? colorScheme.onSecondaryContainer
              //           : colorScheme.onSurfaceVariant,
              //     );
              //   },
              // ),
            );
          }).toList(),
    );
  }
}
