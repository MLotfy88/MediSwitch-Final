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
      // Use theme defaults for elevation, shape, color
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          // Use Column to add the top gradient bar easily
          children: [
            // Thin gradient bar at the top
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
              padding: const EdgeInsets.all(12.0), // Consistent padding
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center items vertically
                children: [
                  // Image Placeholder/Actual Image
                  Container(
                    width: 65, // Slightly larger image
                    height: 65,
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child:
                          drug.imageUrl != null && drug.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: drug.imageUrl!,
                                fit:
                                    BoxFit
                                        .contain, // Use contain to see full image
                                placeholder:
                                    (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Center(
                                      child: Icon(
                                        LucideIcons.pill, // Use Lucide icon
                                        size: 30,
                                        color: colorScheme.onSecondaryContainer
                                            .withOpacity(0.5),
                                      ),
                                    ),
                              )
                              : Center(
                                child: Icon(
                                  LucideIcons.pill, // Use Lucide icon
                                  size: 30,
                                  color: colorScheme.onSecondaryContainer
                                      .withOpacity(0.5),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Center text vertically
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
                        const SizedBox(height: 8), // Spacing
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween, // Space between category and price
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Category Badge
                            if (drug.mainCategory.isNotEmpty)
                              CustomBadge(
                                // Use CustomBadge
                                label: drug.mainCategory,
                                // Use secondary colors for category badge
                                backgroundColor: colorScheme.secondaryContainer,
                                textColor: colorScheme.onSecondaryContainer,
                              ),

                            // Price and Price Change
                            Row(
                              // Row for price and potential change indicator
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .baseline, // Align text baseline
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${_formatPrice(drug.price)} ج.م',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                // Price Change Indicator
                                if (isPriceChanged)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 4.0,
                                    ), // Use start for RTL support
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
                                      ), // Smaller padding
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Favorite Icon (Placeholder) - Keep commented out
                  // IconButton(...)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thumbnail Card Implementation (Updated)
  Widget _buildThumbnailCard(BuildContext context) {
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

    return SizedBox(
      width: 176, // w-44
      child: Card(
        clipBehavior: Clip.antiAlias,
        // Use theme defaults
        child: InkWell(
          onTap: onTap,
          child: Stack(
            // Use Stack for potential badges
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thin gradient bar
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
                  // Content Padding
                  Padding(
                    padding: const EdgeInsets.all(
                      12.0,
                    ), // p-3 in Tailwind (4 * 3 = 12)
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add space to mimic image area removal
                        const SizedBox(height: 8),
                        Text(
                          drug.tradeName,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ), // text-sm font-medium
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),
                        const SizedBox(height: 6), // mt-1 + gap
                        Row(
                          // Row for price and potential change indicator
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween, // Space out price and indicator
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_formatPrice(drug.price)} ج.م',
                              style: textTheme.bodyMedium?.copyWith(
                                // text-sm
                                fontWeight: FontWeight.bold, // font-semibold
                                color: colorScheme.primary,
                              ),
                            ),
                            // Price Change Indicator
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
                                iconSize: 10, // Smaller icon for thumbnail
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ), // Smaller padding
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Popular Badge (Example)
              // Positioned(...)
            ],
          ),
        ),
      ),
    );
  }
}
