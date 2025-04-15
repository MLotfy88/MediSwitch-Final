import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Use Lucide Icons

class CategoryCard extends StatelessWidget {
  final String name;
  final IconData iconData; // Use IconData from Lucide
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.name,
    required this.iconData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SizedBox(
      width: 96, // w-24 in Tailwind (4 * 24 = 96)
      child: Card(
        // Use theme's card theme for consistency
        // Override color slightly for category cards if needed, or use surfaceVariant
        color: colorScheme.surface, // Use surface color from theme
        elevation: 0, // Remove elevation if using border
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Match theme radius
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
          ), // Add subtle border
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 8.0,
            ), // Adjusted padding
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon background Circle
                Container(
                  padding: const EdgeInsets.all(10), // Slightly smaller padding
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(
                      0.10,
                    ), // bg-primary/10
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 24, // h-6 w-6 in Tailwind
                    color: colorScheme.primary, // text-primary
                  ),
                ),
                const SizedBox(height: 8.0), // mb-2
                // Category Name
                Text(
                  name,
                  style: textTheme.bodySmall?.copyWith(
                    // text-xs
                    fontWeight: FontWeight.w500, // font-medium
                    color:
                        colorScheme
                            .onSurfaceVariant, // text-muted-foreground equivalent
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // line-clamp-2
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
