import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';

// DrugUIModel remains as is
class DrugUIModel {
  final String id;
  final String tradeNameEn;
  final String tradeNameAr;
  final String activeIngredient;
  final String form;
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

// StatefulWidget for hover effects
class DrugCard extends StatefulWidget {
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
  State<DrugCard> createState() => _DrugCardState();
}

class _DrugCardState extends State<DrugCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final drug = widget.drug;
    final isRTL = widget.isRTL;

    double priceChange = 0;
    if (drug.oldPrice != null) {
      priceChange =
          ((drug.currentPrice - drug.oldPrice!) / drug.oldPrice!) * 100;
    }
    bool isPriceDown = priceChange < 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _isHovered ? -2 : 0, 0),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? AppColors.card,
              borderRadius: BorderRadius.circular(12),
              boxShadow:
                  _isHovered
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : AppColors.shadowCard,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      onTap: () => widget.onFavoriteToggle?.call(drug.id),
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
                Row(
                  mainAxisAlignment:
                      isRTL ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (isRTL) ...[
                      _buildActiveIngredient(isRTL, drug),
                      const SizedBox(width: 8),
                      const Text(
                        "•",
                        style: TextStyle(color: AppColors.mutedForeground),
                      ),
                      const SizedBox(width: 8),
                      _buildFormBadge(isRTL, drug),
                    ] else ...[
                      _buildFormBadge(isRTL, drug),
                      const SizedBox(width: 8),
                      const Text(
                        "•",
                        style: TextStyle(color: AppColors.mutedForeground),
                      ),
                      const SizedBox(width: 8),
                      _buildActiveIngredient(isRTL, drug),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection:
                          isRTL ? TextDirection.rtl : TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${drug.currentPrice.toStringAsFixed(2)} ${isRTL ? 'ج.م' : 'EGP'}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
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
                          borderRadius: BorderRadius.circular(100),
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
                if (drug.hasInteraction)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            LucideIcons.alertTriangle,
                            size: 14,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Interaction Warning",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBadges(BuildContext context, bool isRTL) {
    return [];
  }

  Widget _buildFormBadge(bool isRTL, DrugUIModel drug) {
    IconData icon;
    switch (drug.form.toLowerCase()) {
      case 'tablet':
        icon = LucideIcons.pill;
        break;
      case 'syrup':
        icon = LucideIcons.beaker;
        break;
      case 'injection':
        icon = LucideIcons.syringe;
        break;
      case 'cream':
        icon = LucideIcons.package;
        break;
      case 'drops':
        icon = LucideIcons.droplet;
        break;
      default:
        icon = LucideIcons.pill;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.mutedForeground),
        const SizedBox(width: 4),
        Text(
          drug.form,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveIngredient(bool isRTL, DrugUIModel drug) {
    return Flexible(
      child: Text(
        drug.activeIngredient,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: isRTL ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}
