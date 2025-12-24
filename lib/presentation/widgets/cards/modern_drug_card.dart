import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/utils/date_formatter.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/widgets/modern_badge.dart';

class ModernDrugCard extends StatelessWidget {
  final DrugEntity drug;
  final bool isFavorite;
  final bool hasDrugInteraction;
  final bool hasFoodInteraction;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const ModernDrugCard({
    super.key,
    required this.drug,
    this.isFavorite = false,
    this.hasDrugInteraction = false,
    this.hasFoodInteraction = false,
    this.onTap,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20), // More rounded
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: isDark ? 0.3 : 0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: -2,
            ),
          ],
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: isDark ? 0.1 : 0.05),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              drug.tradeName,
                              style: TextStyle(
                                fontSize: 17, // Slightly larger
                                fontWeight: FontWeight.w700, // Bolder
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        drug.nameAr,
                        style: TextStyle(
                          fontSize: 14,
                          color: appColors.mutedForeground,
                          fontFamily: 'Cairo', // Ensure Arabic font usage
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
                // Top-right badges (NEW / POPULAR)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (drug.isNew)
                      const ModernBadge(
                        text: 'NEW',
                        variant: BadgeVariant.newBadge,
                        size: BadgeSize.sm,
                      ),
                    if (drug.isPopular) ...[
                      if (drug.isNew) const SizedBox(height: 4),
                      const ModernBadge(
                        text: 'POPULAR',
                        variant: BadgeVariant.popular,
                        size: BadgeSize.sm,
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Form & Ingredient
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFormIcon(drug.form),
                        size: 14,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        drug.form,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.flaskConical,
                        size: 14,
                        color: appColors.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          drug.active,
                          style: TextStyle(
                            fontSize: 13,
                            color: appColors.mutedForeground,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),

            // Price & Interaction Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${drug.price} EGP',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (drug.oldPrice != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${drug.oldPrice}',
                            style: TextStyle(
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                              color: appColors.mutedForeground.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPriceChangeBadge(),
                        ],
                      ],
                    ),
                  ],
                ),

                // Interaction warnings row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDrugInteraction)
                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: appColors.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.alertTriangle,
                          size: 16,
                          color: appColors.danger,
                        ),
                      ),
                    if (hasFoodInteraction)
                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: appColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.alertTriangle,
                          size: 16,
                          color: appColors.warning,
                        ),
                      ),
                    if (!hasDrugInteraction &&
                        !hasFoodInteraction &&
                        drug.lastPriceUpdate.isNotEmpty)
                      Text(
                        DateFormatter.formatDate(drug.lastPriceUpdate),
                        style: TextStyle(
                          fontSize: 11,
                          color: appColors.mutedForeground.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFormIcon(String form) {
    switch (form.toLowerCase()) {
      case 'syrup':
      case 'drops':
        return LucideIcons
            .droplets; // Lucide doesn't have individual droplets sometimes, check validity or fallback
      case 'injection':
        return LucideIcons.syringe;
      case 'tablet':
      case 'capsule':
      default:
        return LucideIcons.pill;
    }
  }

  /// Build price change badge (priceDown or priceUp)
  Widget _buildPriceChangeBadge() {
    final currentPrice = double.tryParse(drug.price) ?? 0;
    final oldPrice = double.tryParse(drug.oldPrice ?? '') ?? 0;

    if (oldPrice <= 0 || currentPrice <= 0) {
      return const SizedBox.shrink();
    }

    final percentChange = ((currentPrice - oldPrice) / oldPrice * 100).abs();
    final isPriceDown = currentPrice < oldPrice;

    return ModernBadge(
      text: '${percentChange.toStringAsFixed(0)}%',
      variant: isPriceDown ? BadgeVariant.priceDown : BadgeVariant.priceUp,
      size: BadgeSize.sm,
    );
  }
}
