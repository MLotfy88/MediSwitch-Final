import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    icon: LucideIcons.home,
                    label: 'Home',
                    labelAr: 'الرئيسية',
                    index: 0,
                  ),
                  _buildNavItem(
                    context,
                    icon: LucideIcons.search,
                    label: 'Search',
                    labelAr: 'بحث',
                    index: 1,
                  ),
                  _buildNavItem(
                    context,
                    icon: LucideIcons.history,
                    label: 'History',
                    labelAr: 'السجل',
                    index: 2,
                  ),
                  _buildNavItem(
                    context,
                    icon: LucideIcons.heart,
                    label: 'Favorites',
                    labelAr: 'المفضلة',
                    index: 3,
                  ),
                  _buildNavItem(
                    context,
                    icon: LucideIcons.settings,
                    label: 'Settings',
                    labelAr: 'الإعدادات',
                    index: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String labelAr,
    required int index,
  }) {
    final theme = Theme.of(context);
    final isActive = currentIndex == index;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color:
                      isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 4),
                Text(
                  isRTL ? labelAr : label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
