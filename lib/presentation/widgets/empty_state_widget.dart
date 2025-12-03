import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryText;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon = LucideIcons.searchX,
    this.onRetry,
    this.retryText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(retryText ?? 'إعادة المحاولة'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
