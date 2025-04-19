import 'dart:ui' as ui; // Import dart:ui with alias
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import '../../domain/entities/drug_entity.dart';

// Helper widget for displaying a drug item in the list/grid
class DrugListItem extends StatelessWidget {
  final DrugEntity drug;
  final VoidCallback onTap;

  const DrugListItem({
    super.key, // Add super.key
    required this.drug,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
          // Removed default margin, handled by parent list/grid padding/spacing
          elevation: 1.5, // Slightly more elevation for cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          clipBehavior: Clip.antiAlias, // Clip image to card shape
          child: InkWell(
            // Make the whole card tappable
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section - Wrapped with Hero
                Hero(
                  // Create a unique tag for the Hero animation
                  tag:
                      'drug_image_${drug.tradeName}', // Use tradeName or a unique ID if available
                  child: AspectRatio(
                    aspectRatio: 16 / 10, // Adjust aspect ratio as needed
                    child: Container(
                      color: colorScheme.surfaceVariant.withOpacity(
                        0.5,
                      ), // Background for placeholder
                      child:
                          drug.imageUrl != null && drug.imageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                imageUrl: drug.imageUrl!,
                                placeholder:
                                    (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                      ),
                                    ),
                                errorWidget:
                                    (context, url, error) => Icon(
                                      Icons.medication_liquid_outlined,
                                      color: colorScheme.onSurfaceVariant
                                          .withOpacity(0.5),
                                      size: 40,
                                    ),
                                fit: BoxFit.cover,
                              )
                              : Icon(
                                // Placeholder icon if no image
                                Icons.medication_liquid_outlined,
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.5,
                                ),
                                size: 40,
                              ),
                    ),
                  ),
                ),
                // Text Section
                Padding(
                  padding: const EdgeInsets.all(
                    10.0,
                  ), // Padding for text content
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drug.tradeName,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (drug.arabicName.isNotEmpty &&
                          drug.arabicName != drug.tradeName)
                        Text(
                          drug.arabicName,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${drug.price} L.E', // Use L.E consistently
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textDirection: ui.TextDirection.ltr, // Force LTR
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate() // Add animate extension
        .fadeIn(duration: 400.ms, curve: Curves.easeOut) // Fade in effect
        .slideY(
          begin: 0.1,
          duration: 400.ms,
          curve: Curves.easeOut,
        ); // Slight slide up effect
  }
}
