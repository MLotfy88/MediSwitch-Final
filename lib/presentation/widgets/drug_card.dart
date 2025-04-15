import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:lucide_icons/lucide_icons.dart'; // Use Lucide Icons
import '../../domain/entities/drug_entity.dart';
// import 'package:provider/provider.dart'; // Not needed directly here
// import '../bloc/settings_provider.dart'; // Not needed directly here
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
    if (price == null) {
      return priceString;
    }
    return NumberFormat("#,##0.##", "en_US").format(price);
  }

  @override
  Widget build(BuildContext context) {
    // Use detailed card for now as it's used in HomeScreen/SearchScreen lists
    return _buildDetailedCard(context);
  }

  // Detailed Card Implementation
  Widget _buildDetailedCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    // Price change logic (can be uncommented if oldPrice is added to DrugEntity)
    // final double? oldPriceValue = double.tryParse(drug.oldPrice ?? '');
    // final double? currentPriceValue = double.tryParse(drug.price);
    // final bool isPriceChanged = oldPriceValue != null && currentPriceValue != null && oldPriceValue != currentPriceValue;
    // final bool isPriceIncreased = isPriceChanged && currentPriceValue! > oldPriceValue!;
    // final double priceChangePercentage = isPriceChanged ? ( (currentPriceValue! - oldPriceValue!) / oldPriceValue! * 100 ).abs() : 0;

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
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image Placeholder/Actual Image
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
                                        color: colorScheme.onSecondaryContainer
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
                  // Text Content
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
                                // Price Change Indicator (Deferred)
                                // if (isPriceChanged)
                                //   Padding(
                                //     padding: const EdgeInsets.only(right: 4.0), // Add space
                                //     child: CustomBadge(
                                //       label: '${isPriceIncreased ? '+' : '-'}${priceChangePercentage.toStringAsFixed(0)}%',
                                //       backgroundColor: isPriceIncreased ? colorScheme.errorContainer : Colors.green.shade100, // Use appropriate colors
                                //       textColor: isPriceIncreased ? colorScheme.onErrorContainer : Colors.green.shade900,
                                //       icon: isPriceIncreased ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                                //       iconSize: 12,
                                //     ),
                                //   ),
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

  // Thumbnail Card Implementation (Keep for reference)
  Widget _buildThumbnailCard(BuildContext context) {
    // ... (previous implementation remains unchanged for now) ...
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
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
              Container(
                height: 90,
                width: double.infinity,
                color: colorScheme.secondaryContainer.withOpacity(0.3),
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
                                  size: 40,
                                  color: colorScheme.onSecondaryContainer
                                      .withOpacity(0.5),
                                ),
                              ),
                        )
                        : Center(
                          child: Icon(
                            LucideIcons.pill,
                            size: 40,
                            color: colorScheme.onSecondaryContainer.withOpacity(
                              0.5,
                            ),
                          ),
                        ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drug.tradeName,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatPrice(drug.price)} ج.م',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
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
}
