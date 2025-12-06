import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../bloc/settings_provider.dart';
import '../theme/app_colors.dart';

/// Floating theme and language toggle buttons
/// Matches design-refresh/src/components/layout/ThemeToggle.tsx
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark = settingsProvider.themeMode == ThemeMode.dark;
    final isArabic = settingsProvider.locale.languageCode == 'ar';

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Language Toggle
          _buildToggleButton(
            context,
            icon: LucideIcons.globe,
            label: isArabic ? 'EN' : 'عربي',
            onTap: () {
              final newLocale =
                  isArabic ? const Locale('en') : const Locale('ar');
              settingsProvider.updateLocale(newLocale);
            },
          ),
          const SizedBox(width: 8),

          // Theme Toggle
          _buildToggleButton(
            context,
            icon: isDark ? LucideIcons.sun : LucideIcons.moon,
            onTap: () {
              final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
              settingsProvider.updateThemeMode(newMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    BuildContext context, {
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              label != null
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: colorScheme.onSurface),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  )
                  : Icon(icon, size: 20, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}
