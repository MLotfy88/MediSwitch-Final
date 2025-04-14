import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:lucide_icons/lucide_icons.dart'; // Use Lucide Icons
import '../../domain/entities/drug_entity.dart';
import 'package:provider/provider.dart'; // To access theme
import '../bloc/settings_provider.dart'; // To access theme mode

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
      return priceString; // Return original string if parsing fails
    }
    // Use a simple format for now, can be localized later
    return NumberFormat("#,##0.##", "en_US").format(price);
  }

  @override
  Widget build(BuildContext context) {
    // Use detailed card for now as it's used in HomeScreen/SearchScreen lists
    return _buildDetailedCard(context);
    // return type == DrugCardType.thumbnail
    //     ? _buildThumbnailCard(context)
    //     : _buildDetailedCard(context);
  }

  // Detailed Card Implementation (Matches design lab more closely)
  Widget _buildDetailedCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    // Determine if price changed (assuming oldPrice might be added later)
    // final double? oldPriceValue = _parsePrice(drug.oldPrice ?? '');
    // final double? currentPriceValue = _parsePrice(drug.price);
    // final bool isPriceChanged = oldPriceValue != null && currentPriceValue != null && oldPriceValue != currentPriceValue;
    // final bool isPriceIncreased = isPriceChanged && currentPriceValue! > oldPriceValue!;
    // final double priceChangePercentage = isPriceChanged ? ( (currentPriceValue! - oldPriceValue!) / oldPriceValue! * 100 ).abs() : 0;

    return Card(
      // Use theme defaults for elevation, shape, color
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
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
                                BoxFit.contain, // Use contain to see full image
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
                    const SizedBox(height: 6), // Spacing
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween, // Space between category and price
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Category Badge (Optional - uncomment if needed)
                        // if (drug.mainCategory.isNotEmpty)
                        //   Badge(
                        //     label: Text(drug.mainCategory),
                        //     backgroundColor: colorScheme.secondaryContainer,
                        //     textColor: colorScheme.onSecondaryContainer,
                        //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        //   ),
                        // Spacer(), // Push price to the end if category exists

                        // Price
                        Text(
                          '${_formatPrice(drug.price)} ج.م',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        // Price Change Indicator (Deferred until oldPrice is available)
                        // if (isPriceChanged) ...
                      ],
                    ),
                  ],
                ),
              ),
              // Favorite Icon (Premium Feature - Placeholder)
              // IconButton(
              //   icon: Icon(LucideIcons.star, size: 20, color: colorScheme.outline),
              //   onPressed: () { /* TODO: Implement favorite toggle */ },
              //   tooltip: 'إضافة للمفضلة (Premium)',
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // Thumbnail Card Implementation (Keep for reference or future use)
  Widget _buildThumbnailCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SizedBox(
      // Ensure thumbnail has a defined width
      width: 150, // Adjust width as needed
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
