import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../screens/search_screen.dart'; // Import SearchScreen
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations

class SearchBarButton extends StatelessWidget {
  const SearchBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get localizations instance
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      // Apply px-4 py-2 padding
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        height: 50.0, // h-10
        width: double.infinity, // w-full
        child: Material(
          // Use Material for InkWell effect and border
          color: colorScheme.surface, // bg-white (use surface)
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              20.0,
            ), // Match input decoration radius
            side: BorderSide(color: colorScheme.outline), // variant="outline"
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20.0),
            // Add hoverColor for web/desktop if needed
            // hoverColor: Colors.grey.shade50, // hover:bg-gray-50
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 13.0,
              ), // Adjust internal padding
              child: Row(
                children: [
                  Icon(
                    LucideIcons.search,
                    size: 16, // h-4 w-4
                    color:
                        colorScheme.onSurfaceVariant, // text-muted-foreground
                  ),
                  const SizedBox(width: 9.0), // gap-2
                  Text(
                    l10n.searchHint, // Use localized string
                    style: textTheme.bodyMedium?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant, // text-muted-foreground
                    ),
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
