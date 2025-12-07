import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors_extension.dart';

class ModernSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onMicTap;
  final String hintText;

  const ModernSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.onMicTap,
    this.hintText = 'Search by Trade Name or Active Ingredient...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.3 : 0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 20, color: appColors.mutedForeground),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: appColors.mutedForeground,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),

          if (onMicTap != null) ...[
            GestureDetector(
              onTap: onMicTap,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  LucideIcons.mic,
                  size: 16,
                  color: appColors.mutedForeground,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
          ],

          if (onFilterTap != null)
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.slidersHorizontal,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
