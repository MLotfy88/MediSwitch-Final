import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.shadowCard,
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.foreground,
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
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
                          isFavorite ? AppColors.dangerSoft : AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.heart,
                      size: 16,
                      color:
                          isFavorite
                              ? AppColors.danger
                              : AppColors.mutedForeground,
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
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFormIcon(drug.form),
                        size: 14,
                        color: AppColors.accentForeground,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        drug.form,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accentForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '•',
                  style: TextStyle(color: AppColors.mutedForeground),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    drug.active, // activeIngredient
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    if (drug.oldPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${drug.oldPrice}',
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.mutedForeground,
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
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Interaction',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
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
