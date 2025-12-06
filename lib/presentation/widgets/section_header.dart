import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget icon;
  final Color? iconBgColor;
  final VoidCallback? onMoreTap;

  const SectionHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconBgColor,
    this.onMoreTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBgColor ?? AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10), // rounded-lg roughly
          ),
          child: IconTheme(
            data: const IconThemeData(size: 16, color: AppColors.primary),
            child: icon,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
        if (onMoreTap != null)
          TextButton(
            onPressed: onMoreTap,
            child: const Text(
              "View All",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
