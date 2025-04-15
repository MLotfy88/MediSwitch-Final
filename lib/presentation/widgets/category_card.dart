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

    // Let the parent HorizontalListSection handle width/spacing
    return Card(
      // Use theme's card theme for consistency
      color: Colors.transparent, // Make card transparent to show gradient below
      elevation: 0, // Remove elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // rounded-lg (8px)
        // No border needed if using gradient background
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        // Use Container for gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.background,
            ], // from-card to-background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Semantics(
          label: 'فئة $name',
          button: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0), // p-3 (12px)
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    MainAxisSize.min, // Ensure column takes minimum space
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      size: 24, // h-6 w-6
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8.0), // mb-2
                  Text(
                    name,
                    style: textTheme.bodyMedium?.copyWith(
                      // text-sm
                      fontWeight: FontWeight.w500, // font-medium
                      color:
                          colorScheme.onSurfaceVariant, // text-muted-foreground
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
