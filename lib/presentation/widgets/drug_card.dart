import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:lucide_icons/lucide_icons.dart'; // Use Lucide Icons
import '../../domain/entities/drug_entity.dart';
import '../widgets/custom_badge.dart'; // Import CustomBadge

enum DrugCardType { thumbnail, detailed }

class DrugCard extends StatelessWidget {
  final DrugEntity drug;
  final VoidCallback? onTap;
  final DrugCardType type;

  const DrugCard({
    super.key,
    required this.drug,
    this.onTap,
    this.type = DrugCardType.detailed,
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
    return double.tryParse(priceString);
  }

  @override
  Widget build(BuildContext context) {
    return type == DrugCardType.thumbnail
        ? _buildThumbnailCard(context)
        : _buildDetailedCard(context);
  }

  // Detailed Card Implementation
  Widget _buildDetailedCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Calculate price change
    final double? oldPriceValue = _parsePrice(drug.oldPrice);
    final double? currentPriceValue = _parsePrice(drug.price);
    final bool isPriceChanged =
        oldPriceValue != null &&
        currentPriceValue != null &&
        oldPriceValue != currentPriceValue;
    final bool isPriceIncreased =
        isPriceChanged && currentPriceValue! > oldPriceValue!;
    final double priceChangePercentage =
        isPriceChanged
            ? ((currentPriceValue! - oldPriceValue!) / oldPriceValue! * 100)
                .abs()
            : 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      // Wrap InkWell with Semantics
      child: Semantics(
        label:
            'تفاصيل دواء ${drug.tradeName}, السعر ${_formatPrice(drug.price)} جنيه', // More descriptive label
        button: true, // Indicate it's tappable
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              Container(
                height: 3.0,
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
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child:
                            drug.imageUrl != null && drug.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                  imageUrl: drug.imageUrl!,
                                  fit: BoxFit.contain,
                                  placeholder:
                                      (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Center(
                                        child: Icon(
                                          LucideIcons.pill,
                                          size: 30,
                                          color: colorScheme
                                              .onSecondaryContainer
                                              .withOpacity(0.5),
                                        ),
                                      ),
                                )
                                : Center(
                                  child: Icon(
                                    LucideIcons.pill,
                                    size: 30,
                                    color: colorScheme.onSecondaryContainer
                                        .withOpacity(0.5),
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            drug.tradeName,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (drug.arabicName.isNotEmpty)
                            Text(
                              drug.arabicName,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (drug.mainCategory.isNotEmpty)
                                CustomBadge(
                                  label: drug.mainCategory,
                                  backgroundColor:
                                      colorScheme.secondaryContainer,
                                  textColor: colorScheme.onSecondaryContainer,
                                ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${_formatPrice(drug.price)} ج.م',
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  if (isPriceChanged)
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 4.0,
                                      ),
                                      child: CustomBadge(
                                        label:
                                            '${isPriceIncreased ? '+' : '-'}${priceChangePercentage.toStringAsFixed(0)}%',
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
                                          horizontal: 5,
                                          vertical: 1,
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
        isPriceChanged
            ? ((currentPriceValue! - oldPriceValue!) / oldPriceValue! * 100)
                .abs()
            : 0;

    return SizedBox(
      width: 176,
      child: Card(
        clipBehavior: Clip.antiAlias,
        // Wrap InkWell with Semantics
        child: Semantics(
          label:
              'تفاصيل دواء ${drug.tradeName}, السعر ${_formatPrice(drug.price)} جنيه',
          button: true,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 3.0,
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
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            drug.tradeName,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.start,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_formatPrice(drug.price)} ج.م',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              if (isPriceChanged)
                                CustomBadge(
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
                                  iconSize: 10,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
