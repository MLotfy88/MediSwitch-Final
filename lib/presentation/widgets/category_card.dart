import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Import Lucide Icons

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

    return SizedBox(
      width: 100, // Approx w-24
      child: Card(
        // Use theme's card theme for consistency (elevation, shape, color)
        // elevation: 1.0, // Use theme default or customize if needed
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Use theme default
        // color: colorScheme.surfaceVariant.withOpacity(0.7), // Use theme default
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0), // Match card shape
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 8.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon background Circle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // Use primary color with opacity from theme
                    color: colorScheme.primary.withOpacity(
                      0.10,
                    ), // bg-primary/10
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size: 28, // h-6 w-6 is 24, design lab uses 28
                    color: colorScheme.primary, // text-primary
                  ),
                ),
                const SizedBox(height: 8.0), // mb-2
                // Category Name
                Text(
                  name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500, // font-medium
                    color:
                        colorScheme
                            .onSurfaceVariant, // Muted foreground equivalent
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
