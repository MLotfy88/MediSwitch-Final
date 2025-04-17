import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:lucide_icons/lucide_icons.dart'; // Use Lucide Icons
import '../../domain/entities/drug_entity.dart';
import '../widgets/custom_badge.dart'; // Import CustomBadge
import '../../core/constants/app_constants.dart'; // Import the constants file

enum DrugCardType { thumbnail, detailed }

class DrugCard extends StatelessWidget {
  final DrugEntity drug;
  final VoidCallback? onTap;
  final DrugCardType type;
  final bool isPopular; // Flag for popular drug
  final bool isAlternative; // Flag for alternative drug
  // REMOVED: categoryTranslation parameter

  const DrugCard({
    super.key,
    required this.drug,
    // REMOVED: required this.categoryTranslation,
    this.onTap,
    this.type = DrugCardType.detailed,
    this.isPopular = false, // Default to false
    this.isAlternative = false, // Default to false
  });

  // Helper to format price after parsing
  String _formatPrice(String priceString) {
    final price = double.tryParse(priceString);
    if (price == null) return priceString;
    return NumberFormat("#,##0.##", "en_US").format(price);
  }

  // Helper to parse price string to double
  double? _parsePrice(String? priceString) {
    if (priceString == null) return null;
    final cleanedPrice = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanedPrice);
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent =
        type == DrugCardType.thumbnail
            ? _buildThumbnailCard(context)
            : _buildDetailedCard(context);

    // Add semantic label for alternative if applicable
    String alternativeLabel = isAlternative ? ' بديل لدواء آخر.' : '';
    String popularLabel = isPopular ? ' دواء شائع.' : '';

    return Semantics(
      label:
          'تفاصيل دواء ${drug.tradeName}, السعر ${_formatPrice(drug.price)} جنيه.$alternativeLabel$popularLabel',
      button: true,
      child: cardContent,
    );
  }

  // Detailed Card Implementation (Matching Design Lab)
  Widget _buildDetailedCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final double? oldPriceValue = _parsePrice(drug.oldPrice);
    final double? currentPriceValue = _parsePrice(drug.price);
    final bool isPriceChanged =
        oldPriceValue != null &&
        currentPriceValue != null &&
        oldPriceValue != currentPriceValue;
    final bool isPriceIncreased =
        isPriceChanged && currentPriceValue! > oldPriceValue!;
    final double priceChangePercentage =
        isPriceChanged && oldPriceValue! != 0
            ? ((currentPriceValue! - oldPriceValue) / oldPriceValue * 100).abs()
            : 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ), // rounded-lg (8px)
      elevation: 1.5,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.surface,
              colorScheme.background,
            ], // from-card to-background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 6.0, // h-1.5
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.15),
                      colorScheme.primary.withOpacity(0.20),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0), // p-4
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            drug.tradeName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ), // text-base font-semibold
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (drug.arabicName.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                drug.arabicName,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ), // text-sm text-muted-foreground
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 8), // mt-2
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                // Wrap category and alternative badge
                                children: [
                                  if (drug.mainCategory.isNotEmpty)
                                    CustomBadge(
                                      // Use translated category name from constants, fallback to original
                                      label:
                                          kCategoryTranslation[drug
                                              .mainCategory] ??
                                          drug.mainCategory,
                                      backgroundColor:
                                          colorScheme.secondaryContainer,
                                      textColor:
                                          colorScheme.onSecondaryContainer,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ), // px-2.5 py-0.5
                                    ),
                                  if (isAlternative) // Show Alternative badge
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 4.0,
                                      ),
                                      child: CustomBadge(
                                        label: 'بديل',
                                        backgroundColor:
                                            colorScheme.primaryContainer,
                                        textColor:
                                            colorScheme.onPrimaryContainer,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  if (isPriceChanged)
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        end: 4.0,
                                      ),
                                      child: CustomBadge(
                                        label:
                                            '${priceChangePercentage.toStringAsFixed(0)}%',
                                        backgroundColor:
                                            isPriceIncreased
                                                ? colorScheme.errorContainer
                                                    .withOpacity(0.7)
                                                : Colors.green.shade100,
                                        textColor:
                                            isPriceIncreased
                                                ? colorScheme.onErrorContainer
                                                : Colors.green.shade900,
                                        icon:
                                            isPriceIncreased
                                                ? LucideIcons.arrowUp
                                                : LucideIcons.arrowDown,
                                        iconSize: 12,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ), // px-2 py-0.5
                                      ),
                                    ),
                                  Text(
                                    '${_formatPrice(drug.price)} ج.م',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ), // text-lg font-bold
                                  ),
                                  if (isPopular) // Show Popular icon
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 4.0,
                                      ),
                                      child: Icon(
                                        LucideIcons.star,
                                        size: 16,
                                        color: Colors.amber.shade600,
                                        semanticLabel: 'دواء شائع',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Thumbnail Card Implementation (Updated)
  Widget _buildThumbnailCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final double? oldPriceValue = _parsePrice(drug.oldPrice);
    final double? currentPriceValue = _parsePrice(drug.price);
    final bool isPriceChanged =
        oldPriceValue != null &&
        currentPriceValue != null &&
        oldPriceValue != currentPriceValue;
    final bool isPriceIncreased =
        isPriceChanged && currentPriceValue! > oldPriceValue!;
    final double priceChangePercentage =
        isPriceChanged && oldPriceValue! != 0
            ? ((currentPriceValue! - oldPriceValue) / oldPriceValue * 100).abs()
            : 0;

    return SizedBox(
      width: 176, // w-44
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ), // rounded-lg (8px)
        elevation: 1.5,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.surface, colorScheme.background],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8.0),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 6.0, // h-1.5
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.05),
                            colorScheme.primary.withOpacity(0.20),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0), // p-3
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 16,
                          ), // Space for potential badge/icon
                          Text(
                            drug.tradeName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ), // text-sm font-medium
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 4), // mt-1
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_formatPrice(drug.price)} ج.م',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ), // text-sm font-semibold
                              ),
                              if (drug.oldPrice != null &&
                                  drug.oldPrice!.isNotEmpty)
                                Text(
                                  '${_formatPrice(drug.oldPrice!)} ج.م',
                                  style: textTheme.labelSmall?.copyWith(
                                    // text-xs
                                    color:
                                        colorScheme
                                            .onSurfaceVariant, // text-muted-foreground
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isPriceChanged)
                  Positioned(
                    bottom: 10,
                    left: 12,
                    child: CustomBadge(
                      label: '${priceChangePercentage.toStringAsFixed(0)}%',
                      backgroundColor:
                          isPriceIncreased
                              ? colorScheme.errorContainer.withOpacity(0.7)
                              : Colors.green.shade100,
                      textColor:
                          isPriceIncreased
                              ? colorScheme.onErrorContainer
                              : Colors.green.shade900,
                      icon:
                          isPriceIncreased
                              ? LucideIcons.arrowUp
                              : LucideIcons.arrowDown,
                      iconSize: 12, // h-3 w-3
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ), // px-1.5 py-0.5
                    ),
                  ),
                // Show Popular icon in top-right corner for thumbnail
                if (isPopular)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      LucideIcons.star,
                      size: 16,
                      color: Colors.amber.shade600,
                      semanticLabel: 'دواء شائع',
                    ),
                  ),
                // Show Alternative badge in top-right corner for thumbnail if not popular
                if (isAlternative && !isPopular)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CustomBadge(
                      label: 'بديل',
                      backgroundColor: colorScheme.primaryContainer,
                      textColor: colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      // textStyle: textTheme.labelSmall?.copyWith(fontSize: 10), // Smaller text
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
