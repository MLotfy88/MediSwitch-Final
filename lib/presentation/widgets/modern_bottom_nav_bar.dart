import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Modern Bottom Navigation Bar
/// Matches design-refresh/src/components/layout/BottomNav.tsx
class ModernBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const ModernBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    final items = [
      _NavItem(
        id: 'home',
        icon: LucideIcons.home,
        labelEn: 'Home',
        labelAr: 'الرئيسية',
      ),
      _NavItem(
        id: 'search',
        icon: LucideIcons.search,
        labelEn: 'Search',
        labelAr: 'بحث',
      ),
      _NavItem(
        id: 'history',
        icon: LucideIcons.history,
        labelEn: 'History',
        labelAr: 'السجل',
      ),
      _NavItem(
        id: 'favorites',
        icon: LucideIcons.heart,
        labelEn: 'Favorites',
        labelAr: 'المفضلة',
      ),
      _NavItem(
        id: 'profile',
        icon: LucideIcons.user,
        labelEn: 'Profile',
        labelAr: 'الحساب',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = selectedIndex == index;

              return Expanded(
                child: _NavButton(
                  icon: item.icon,
                  label: isRTL ? item.labelAr : item.labelEn,
                  isActive: isActive,
                  onTap: () => onItemSelected(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                isActive
                    ? colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    isActive
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color:
                      isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String id;
  final IconData icon;
  final String labelEn;
  final String labelAr;

  _NavItem({
    required this.id,
    required this.icon,
    required this.labelEn,
    required this.labelAr,
  });
}
