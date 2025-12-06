import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';

// Assuming Drug model is reused or we create a UI specific one
class DrugUIModel {
  final String id;
  final String tradeNameEn;
  final String tradeNameAr;
  final String activeIngredient;
  final String form; // tablet, syrup, injection, cream, drops
  final double currentPrice;
  final double? oldPrice;
  final String company;
  final bool isNew;
  final bool isPopular;
  final bool hasInteraction;
  final bool isFavorite;

  DrugUIModel({
    required this.id,
    required this.tradeNameEn,
    required this.tradeNameAr,
    required this.activeIngredient,
    required this.form,
    required this.currentPrice,
    this.oldPrice,
    required this.company,
    this.isNew = false,
    this.isPopular = false,
    this.hasInteraction = false,
    this.isFavorite = false,
  });
}

class DrugCard extends StatelessWidget {
  final DrugUIModel drug;
  final bool isRTL;
  final VoidCallback? onTap;
  final Function(String)? onFavoriteToggle;

  const DrugCard({
    Key? key,
    required this.drug,
    this.isRTL = false,
    this.onTap,
    this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calc price change
    double priceChange = 0;
    if (drug.oldPrice != null) {
      priceChange =
          ((drug.currentPrice - drug.oldPrice!) / drug.oldPrice!) * 100;
    }
    bool isPriceDown = priceChange < 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? AppColors.card,
          borderRadius: BorderRadius.circular(12), // rounded-xl
          boxShadow: AppColors.shadowCard,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        isRTL
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                    children: [
                      // Name + Badge
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment:
                            isRTL ? WrapAlignment.end : WrapAlignment.start,
                        children: [
                          if (isRTL) ..._buildBadges(context, isRTL),
                          Text(
                            isRTL ? drug.tradeNameAr : drug.tradeNameEn,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (!isRTL) ..._buildBadges(context, isRTL),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Subtitle Name
                      Text(
                        isRTL ? drug.tradeNameEn : drug.tradeNameAr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.mutedForeground,
                        ),
                        textAlign: isRTL ? TextAlign.right : TextAlign.left,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onFavoriteToggle?.call(drug.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          drug.isFavorite
                              ? AppColors.dangerSoft
                              : AppColors.muted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.heart,
                      size: 16,
                      color:
                          drug.isFavorite
                              ? AppColors.danger
                              : AppColors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Form & Active Ingredient
            Row(
              mainAxisAlignment:
                  isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (isRTL) ...[
                  _buildActiveIngredient(isRTL),
                  const SizedBox(width: 8),
                  const Text(
                    "•",
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(width: 8),
                  _buildFormBadge(isRTL),
                ] else ...[
                  _buildFormBadge(isRTL),
                  const SizedBox(width: 8),
                  const Text(
                    "•",
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                  const SizedBox(width: 8),
                  _buildActiveIngredient(isRTL),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Price Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Price
                Row(
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${drug.currentPrice.toStringAsFixed(2)} ${isRTL ? 'ج.م' : 'EGP'}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (drug.oldPrice != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        drug.oldPrice!.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),

                // Price Change Badge
                if (priceChange != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isPriceDown
                              ? AppColors.successSoft
                              : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPriceDown
                              ? LucideIcons.trendingDown
                              : LucideIcons.trendingUp,
                          size: 12,
                          color:
                              isPriceDown
                                  ? AppColors.success
                                  : AppColors.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${priceChange.abs().toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isPriceDown
                                    ? AppColors.success
                                    : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Interaction Warning
            if (drug.hasInteraction)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      size: 16,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isRTL ? 'تحذير: تفاعل دوائي' : 'Interaction Warning',
                      style: const TextStyle(
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
      ),
    );
  }

  List<Widget> _buildBadges(BuildContext context, bool isRTL) {
    if (!drug.isNew && !drug.isPopular) return [];

    final badges = <Widget>[];
    if (drug.isNew) {
      badges.add(
        _Badge(text: isRTL ? 'جديد' : 'NEW', color: AppColors.success),
      );
    }
    if (drug.isPopular) {
      badges.add(
        _Badge(text: isRTL ? 'رائج' : 'POPULAR', color: AppColors.primary),
      );
    }

    // spacing
    return badges
        .map(
          (b) => Padding(
            padding: EdgeInsets.only(left: isRTL ? 0 : 8, right: isRTL ? 8 : 0),
            child: b,
          ),
        )
        .toList();
  }

  Widget _buildFormBadge(bool isRTL) {
    IconData icon;
    String label;

    switch (drug.form) {
      case 'tablet':
        icon = LucideIcons.pill;
        label = isRTL ? 'أقراص' : 'Tablet';
        break;
      case 'syrup':
        icon = LucideIcons.droplets;
        label = isRTL ? 'شراب' : 'Syrup';
        break;
      case 'injection':
        icon = LucideIcons.syringe;
        label = isRTL ? 'حقن' : 'Injection';
        break;
      case 'cream':
        icon = LucideIcons.pipette;
        label = isRTL ? 'كريم' : 'Cream';
        break; // Approximate
      case 'drops':
        icon = LucideIcons.droplets;
        label = isRTL ? 'قطرة' : 'Drops';
        break;
      default:
        icon = LucideIcons.pill;
        label = drug.form;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentForeground),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.accentForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveIngredient(bool isRTL) {
    return Expanded(
      child: Text(
        drug.activeIngredient,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
        textAlign: isRTL ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
