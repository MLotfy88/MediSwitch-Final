import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // For number formatting
import '../../domain/entities/drug_entity.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // Removed

enum DrugCardType { thumbnail, detailed }

class DrugCard extends StatelessWidget {
  final DrugEntity drug;
  final VoidCallback? onTap;
  final DrugCardType type;
  // final bool isPopular; // Removed placeholder

  const DrugCard({
    super.key,
    required this.drug,
    this.onTap,
    this.type = DrugCardType.detailed,
    // this.isPopular = false, // Removed placeholder
  });

  // Helper to format price after parsing
  String _formatPrice(String priceString) {
    final price = double.tryParse(priceString);
    if (price == null) {
      return priceString; // Return original string if parsing fails
    }
    return NumberFormat("#,##0.##", "en_US").format(price);
  }

  // Helper to safely parse price string to double
  double? _parsePrice(String priceString) {
    return double.tryParse(priceString);
  }

  @override
  Widget build(BuildContext context) {
    return type == DrugCardType.thumbnail
        ? _buildThumbnailCard(context)
        : _buildDetailedCard(context);
  }

  Widget _buildThumbnailCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    // Removed price change logic as oldPrice is not available

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          // Use Stack for badges
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thin gradient bar at the top
                Container(
                  height: 3.0, // Adjust height
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
                // Image or Placeholder
                Container(
                  height: 90, // Adjust height for image area
                  width: double.infinity,
                  color: colorScheme.secondaryContainer.withOpacity(0.3),
                  // Use CachedNetworkImage if imageUrl is available
                  child:
                      drug.imageUrl != null && drug.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                            imageUrl: drug.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Center(
                                  child: Icon(
                                    Icons.medication_outlined,
                                    size: 40,
                                    color: colorScheme.onSecondaryContainer
                                        .withOpacity(0.5),
                                  ),
                                ), // Show placeholder on error
                          )
                          : Center(
                            child: Icon(
                              Icons.medication_outlined,
                              size: 40,
                              color: colorScheme.onSecondaryContainer
                                  .withOpacity(0.5),
                            ),
                          ), // Placeholder if no URL
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
                      // Removed price change indicator
                    ],
                  ),
                ),
              ],
            ),
            // Removed popular Badge
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    // Removed price change logic

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              children: [
                // Thin gradient bar at the top
                Container(
                  height: 3.0, // Adjust height
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image or Placeholder
                      Container(
                        width: 60, // Adjust size
                        height: 60,
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer.withOpacity(
                            0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // Use CachedNetworkImage if imageUrl is available
                        child: ClipRRect(
                          // Clip the image to the container's border radius
                          borderRadius: BorderRadius.circular(8.0),
                          child:
                              drug.imageUrl != null && drug.imageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                    imageUrl: drug.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Center(
                                          child: Icon(
                                            Icons.medication_outlined,
                                            size: 30,
                                            color: colorScheme
                                                .onSecondaryContainer
                                                .withOpacity(0.5),
                                          ),
                                        ), // Show placeholder on error
                                  )
                                  : Center(
                                    child: Icon(
                                      Icons.medication_outlined,
                                      size: 30,
                                      color: colorScheme.onSecondaryContainer
                                          .withOpacity(0.5),
                                    ),
                                  ), // Placeholder if no URL
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              mainAxisAlignment:
                                  MainAxisAlignment.end, // Align price to end
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Removed Category Badge
                                // Price
                                Text(
                                  '${_formatPrice(drug.price)} ج.م',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                // Removed price change indicator
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
            // Removed popular Badge
          ],
        ),
      ),
    );
  }
}
