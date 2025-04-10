import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // For animations

class CategoryCard extends StatelessWidget {
  final String name;
  final IconData iconData;
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

    // Mimic card-hover effect (can be enhanced)
    // We'll use the build-time animation for now as applied in HomeScreen previously
    // A tap-specific animation would require converting this to StatefulWidget

    return SizedBox(
      width: 100, // Corresponds roughly to w-24 in Tailwind
      child: Card(
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ), // Match theme --radius
        // Use surfaceVariant or similar for background, consistent with HomeScreen
        color: colorScheme.surfaceVariant.withOpacity(0.7),
        clipBehavior: Clip.antiAlias, // Ensure InkWell splash is clipped
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14.0,
              horizontal: 8.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon background
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(
                      0.1,
                    ), // bg-primary/10
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconData,
                    size:
                        30, // h-6 w-6 roughly corresponds to 24, let's make it slightly larger
                    color: colorScheme.primary, // text-primary
                  ),
                ),
                const SizedBox(height: 10.0), // mb-2 roughly 8px, adjusted
                // Category Name
                Text(
                  name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    // text-xs font-medium
                    fontWeight: FontWeight.w500, // medium weight
                    color: colorScheme.onSurfaceVariant,
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
