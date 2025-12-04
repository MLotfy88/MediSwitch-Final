import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/drug_entity.dart';

class PriceAlertsCard extends StatelessWidget {
  /// Creates a [PriceAlertsCard] to display drugs with significant price changes.
  const PriceAlertsCard({required this.topChangedDrugs, super.key});

  /// List of drugs with the biggest price changes.
  final List<DrugEntity> topChangedDrugs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    if (topChangedDrugs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.trendingUp,
                size: 24,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.biggestChangesToday,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price changes list
          ...topChangedDrugs.take(3).map((drug) {
            return _buildPriceChangeItem(context, drug);
          }),
        ],
      ),
    );
  }

  Widget _buildPriceChangeItem(BuildContext context, DrugEntity drug) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final oldPrice = double.tryParse(drug.oldPrice ?? '0') ?? 0;
    final currentPrice = double.tryParse(drug.price) ?? 0;

    if (oldPrice == 0 || currentPrice == 0 || oldPrice == currentPrice) {
      return const SizedBox.shrink();
    }

    final isIncrease = currentPrice > oldPrice;
    final percentageChange = ((currentPrice - oldPrice) / oldPrice * 100).abs();
    final displayName =
        drug.arabicName.isNotEmpty ? drug.arabicName : drug.tradeName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow, // Cleaner background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Icon
          Icon(
            isIncrease ? LucideIcons.arrowUp : LucideIcons.arrowDown,
            size: 20,
            color: isIncrease ? Colors.red.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 12),

          // Drug info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatPrice(oldPrice)} ← '
                  '${_formatPrice(currentPrice)} ج.م',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Percentage badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isIncrease ? Colors.red.shade600 : Colors.green.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isIncrease ? '+' : '-'}'
              '${percentageChange.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return NumberFormat('#,##0.##', 'en_US').format(price);
  }
}
