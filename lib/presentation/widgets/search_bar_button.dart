import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Use lucide_icons
import 'package:provider/provider.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../screens/search_screen.dart'; // To navigate
import '../services/ad_service.dart'; // To increment ad counter

class SearchBarButton extends StatelessWidget {
  const SearchBarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final logger = locator<FileLoggerService>();
    final adService = locator<AdService>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          logger.i("SearchBarButton: Tapped, navigating to SearchScreen.");
          adService.incrementUsageCounterAndShowAdIfNeeded();
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const SearchScreen(),
            ), // Navigate without initial query
          );
        },
        child: Container(
          height: 48, // Consistent height
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            // Use surface color which adapts to light/dark mode
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28.0), // Fully rounded
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.5),
            ), // Subtle border
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.search,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ), // Use onSurfaceVariant for muted icon color
              const SizedBox(width: 12.0),
              Text(
                'ابحث عن دواء...',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ), // Use onSurfaceVariant for muted text
              ),
            ],
          ),
        ),
      ),
    );
  }
}
