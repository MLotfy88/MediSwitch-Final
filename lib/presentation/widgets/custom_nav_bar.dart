import 'dart:ui';

import 'package:flutter/material.dart';

import '../../presentation/theme/app_colors.dart';

// Data class for navigation bar items
class NavBarItem {
  final IconData icon;
  final String label;

  const NavBarItem({required this.icon, required this.label});
}

// Custom Navigation Bar Widget matching BottomNav.tsx
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

    // Using ClipRRect and BackdropFilter for blur effect
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.95), // bg-surface/95
            border: const Border(
              top: BorderSide(
                color: AppColors.border, // border-border
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(context).padding.bottom + 8, // safe-area + py-2
            top: 8,
            left: 8,
            right: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == selectedIndex;
              final color =
                  isActive ? colorScheme.primary : AppColors.mutedForeground;

              return InkWell(
                onTap: () => onItemSelected(index),
                borderRadius: BorderRadius.circular(12), // rounded-xl
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ), // px-4 py-2
                  decoration: BoxDecoration(
                    color:
                        isActive
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : Colors
                                .transparent, // bg-primary/10 or transparent
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 20, // w-5 h-5
                        color: color,
                      ),
                      const SizedBox(height: 4), // gap-1
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10, // text-[10px]
                          fontWeight: FontWeight.w500, // font-medium
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
