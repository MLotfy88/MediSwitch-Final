import 'package:flutter/material.dart';
import '../theme/app_colors_extension.dart';

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
            color:
                iconBgColor ??
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10), // rounded-lg roughly
          ),
          child: IconTheme(
            data: IconThemeData(
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).appColors.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
        if (onMoreTap != null)
          TextButton(
            onPressed: onMoreTap,
            child: Text(
              "View All",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
