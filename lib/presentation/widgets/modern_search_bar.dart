import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors_extension.dart';

/// Modern Search Bar - Improved design without mic
class ModernSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSearchTap;
  final String? hintText;

  const ModernSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.onSearchTap,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final isDark = theme.brightness == Brightness.dark;

    // Determine hint text based on locale if not provided
    final String effectiveHintText =
        hintText ??
        (Localizations.localeOf(context).languageCode == 'ar'
            ? 'ابحث عن دواء...'
            : 'Search for a medicine...');

    return GestureDetector(
      onTap: onSearchTap,
      child: Container(
        // ✅ زيادة الارتفاع ليتناسب مع الكارت
        height: 64,
        // ✅ تحسين المسافات حول الحقل
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
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
            Icon(
              LucideIcons.search,
              size: 24,
              color: appColors.mutedForeground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: (value) {
                  onChanged?.call(value);
                  // Force rebuild to show/hide clear icon
                },
                onTap: onSearchTap,
                decoration: InputDecoration(
                  hintText: effectiveHintText,
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: appColors.mutedForeground,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  // Add Clear Button
                  suffixIcon:
                      controller != null && controller!.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: appColors.mutedForeground,
                            onPressed: () {
                              controller?.clear();
                              onChanged?.call(''); // Trigger search clear logic
                            },
                          )
                          : null,
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ✅ إزالة المايك - لم يعد موجوداً
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
      ),
    );
  }
}
