import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/utils/date_formatter.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/widgets/modern_badge.dart';

class ModernDrugCard extends StatelessWidget {
  final DrugEntity drug;
  final bool isFavorite;
  final bool hasInteraction;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;

  const ModernDrugCard({
    super.key,
    required this.drug,
    this.isFavorite = false,
    this.hasInteraction = false,
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: isDark ? 0.3 : 0.06),
              offset: const Offset(0, 2),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            // Header Row: Name & Badges + Fav Button
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // NEW badge for new drugs
                          if (drug.isNew) ...[
                            const ModernBadge(
                              text: 'NEW',
                              variant: BadgeVariant.newBadge,
                              size: BadgeSize.sm,
                            ),
                            const SizedBox(width: 4),
                          ],
                          // POPULAR badge
                          if (drug.isPopular) ...[
                            const ModernBadge(
                              text: 'POPULAR',
                              variant: BadgeVariant.popular,
                              size: BadgeSize.sm,
                            ),
                            const SizedBox(width: 4),
                          ],
                        ],
                      ),
                      Text(
                        drug.nameAr,
                        style: TextStyle(
                          fontSize: 14,
                          color: appColors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onFavoriteToggle,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isFavorite
                              ? appColors.dangerSoft
                              : theme.colorScheme.surface.withValues(
                                alpha: isDark ? 0.3 : 0.5,
                              ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.heart,
                      size: 16,
                      color:
                          isFavorite
                              ? appColors.dangerForeground
                              : appColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Form & Ingredient
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        appColors.infoSoft, // Better visibility in both themes
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFormIcon(drug.form),
                        size: 14,
                        color: appColors.infoForeground, // Clear contrast
                      ),
                      const SizedBox(width: 6),
                      Text(
                        drug.form,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: appColors.infoForeground, // Clear contrast
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(color: appColors.mutedForeground)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    drug.active, // activeIngredient
                    style: TextStyle(
                      fontSize: 12,
                      color: appColors.mutedForeground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Price & Interaction
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${drug.price} EGP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (drug.oldPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${drug.oldPrice}',
                        style: TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: appColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Price change badge
                      _buildPriceChangeBadge(),
                    ],
                  ],
                ),

                if (hasInteraction)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: appColors.dangerSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          size: 16,
                          color: appColors.dangerForeground,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Interaction',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: appColors.dangerForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Last Updated Date
            if (drug.lastPriceUpdate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 12,
                    color: appColors.mutedForeground,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated: ${DateFormatter.formatDate(drug.lastPriceUpdate)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: appColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
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
