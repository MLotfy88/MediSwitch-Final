import 'dart:ui' as ui; // Import dart:ui with alias
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/repositories/interaction_repository.dart';
import '../../core/di/locator.dart';

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
    final interactionRepo = locator<InteractionRepository>();
    final hasInteractions = interactionRepo.hasKnownInteractions(drug);

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
                // Text Section
                Padding(
                  padding: const EdgeInsets.all(
                    10.0,
                  ), // Padding for text content
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              drug.tradeName,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Warning icon if drug has interactions
                          if (hasInteractions)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                LucideIcons.alertTriangle,
                                size: 14,
                                color: Colors.amber.shade800,
                              ),
                            ),
                        ],
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
