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
      backgroundColor: colorScheme.surface, // Use surface color from theme
      indicatorColor:
          colorScheme.primaryContainer, // Use primary container for indicator
      height: 65, // Adjust height if needed
      labelBehavior:
          NavigationDestinationLabelBehavior.alwaysShow, // Show labels always
      destinations:
          items.map((item) {
            // Use Semantics for better accessibility
            return NavigationDestination(
              icon: Semantics(
                label: item.label, // Describe the icon's purpose
                child: Icon(
                  item.icon,
                  color:
                      colorScheme
                          .onSurfaceVariant, // Muted color for unselected
                ),
              ),
              selectedIcon: Semantics(
                label: item.label,
                child: Icon(
                  item.icon,
                  color:
                      colorScheme
                          .onPrimaryContainer, // Color when inside indicator
                ),
              ),
              label: item.label,
              tooltip: item.label, // Add tooltip for hover/long-press
            );
          }).toList(),
    );
  }
}
