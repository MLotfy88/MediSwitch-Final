import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../presentation/theme/app_colors.dart';

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.shadowCard,
        border: Border.all(color: Colors.transparent, width: 2),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.search,
            size: 20,
            color: AppColors.mutedForeground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14, color: AppColors.foreground),
            ),
          ),
          const SizedBox(width: 8),

          if (onMicTap != null) ...[
            GestureDetector(
              onTap: onMicTap,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  LucideIcons.mic,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
            Container(width: 1, height: 24, color: AppColors.border),
          ],

          if (onFilterTap != null)
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.slidersHorizontal,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
