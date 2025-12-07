import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Using surface color (white in light, darkSurface in dark)
    // to match bg-surface/95 spec
    final backgroundColor = theme.colorScheme.surface.withValues(alpha: 0.95);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // blur-lg = ~16px
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56, // ~py-2 + content roughly 56px per spec estimate
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
                    icon: LucideIcons.user,
                    label: 'Profile',
                    labelAr: 'الحساب',
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(
          18,
        ), // rounded-xl refers to 12px or 16px? Tailwind rounded-xl is 0.75rem = 12px usually, but spec said 18px. Adhering to spec text: 18px.
        child: Container(
          // px-4 py-2 => horizontal: 16, vertical: 8
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color:
                isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(18), // Spec: rounded-xl -> 18px
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20, // w-5 h-5
                color:
                    isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ), // text-muted-foreground
              ),
              const SizedBox(height: 4), // gap-1 (4px)
              Text(
                isRTL ? labelAr : label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500, // font-medium
                  color:
                      isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
