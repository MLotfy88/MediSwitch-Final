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
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        // Wrap InkWell with Semantics
        child: Semantics(
          label: 'فئة $name', // Describe the category
          button: true, // Indicate it's tappable
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: 8.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      size: 24,
                      color: colorScheme.primary,
                      // Add semantics label for the icon itself if needed
                      // semanticLabel: '$name icon',
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    name,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
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
