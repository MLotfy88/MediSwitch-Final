// Import logger first
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import 'dart:ui' as ui; // Explicitly import dart:ui with alias

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:lucide_icons/lucide_icons.dart'; // Use Lucide Icons
import '../../domain/entities/drug_entity.dart';
import '../widgets/custom_badge.dart'; // Import CustomBadge
import '../../core/constants/app_constants.dart'; // Import the constants file
import '../../core/constants/app_spacing.dart'; // Import spacing constants

enum DrugCardType { thumbnail, detailed }

class DrugCard extends StatelessWidget {
  final FileLoggerService _logger =
      locator<FileLoggerService>(); // Add logger instance
  final DrugEntity drug;
  final VoidCallback? onTap;
  final DrugCardType type;
  final bool isPopular; // Flag for popular drug
  final bool isAlternative; // Flag for alternative drug

  DrugCard({
    super.key,
    required this.drug,
    this.onTap,
    this.type = DrugCardType.detailed,
    this.isPopular = false,
    this.isAlternative = false,
  });

  // Helper to format price after parsing
  String _formatPrice(String priceString) {
    final price = double.tryParse(priceString);
    if (price == null) return priceString;
    // Use a locale that supports Arabic numerals if needed, or keep en_US for consistency
    return NumberFormat("#,##0.##", "en_US").format(price);
  }

  // Helper to parse price string to double
  double? _parsePrice(String? priceString) {
    if (priceString == null) return null;
    final cleanedPrice = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanedPrice);
  }

  // Helper to format dosage string
  String _formatDosage(DrugEntity drug) {
    String dosage = drug.dosageForm;
    if (drug.concentration > 0) {
      // Format concentration nicely (remove trailing .0)
      String concentrationStr = drug.concentration.toStringAsFixed(
        drug.concentration.truncateToDouble() == drug.concentration ? 0 : 1,
      );
      dosage += ' $concentrationStr ${drug.unit}';
    }
    return dosage.trim();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final displayName =
        (isArabic && drug.arabicName.isNotEmpty)
            ? drug.arabicName
            : drug.tradeName;

    _logger.v(
      "DrugCard build: type=$type, drug=$displayName (locale: ${locale.languageCode}), popular=$isPopular, alternative=$isAlternative",
    );

    Widget cardContent =
        type == DrugCardType.thumbnail
            ? _buildThumbnailCard(context)
            : _buildDetailedCard(context);

    String alternativeLabel = isAlternative ? ' بديل لدواء آخر.' : '';
    String popularLabel = isPopular ? ' دواء شائع.' : '';
    String dosageLabel = _formatDosage(drug);
    String activeIngredientLabel =
        drug.active.isNotEmpty
            ? ', المادة الفعالة: ${drug.active}'
            : ''; // Added for Semantics

    // Update Semantics label to use the displayed name
    return Semantics(
      label:
          '$displayName$activeIngredientLabel, $dosageLabel, السعر ${_formatPrice(drug.price)} L.E.$alternativeLabel$popularLabel', // Updated currency
      button: true,
      child: cardContent,
    );
  }

  // --- Detailed Card Implementation (Redesigned) ---
  Widget _buildDetailedCard(BuildContext context) {
    _logger.v(
      "DrugCard _buildDetailedCard: drug=${drug.tradeName}",
    ); // Keep original log for consistency if needed
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final displayName =
        (isArabic && drug.arabicName.isNotEmpty)
            ? drug.arabicName
            : drug.tradeName;

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
        isPriceChanged && oldPriceValue != null && oldPriceValue != 0
            ? ((currentPriceValue! - oldPriceValue) / oldPriceValue * 100).abs()
            : 0;

    final String dosageString = _formatDosage(drug);

    return Card(
      // Using Card properties defined in main.dart theme
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppSpacing.medium,
        ), // Match theme card radius (12)
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional: Top highlight bar if needed by design
            // Container( ... ),
            Padding(
              padding: AppSpacing.edgeInsetsAllLarge, // p-4 (16px)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Drug Names ---
                  // --- Drug Name (Localized) ---
                  Text(
                    displayName, // Use localized name
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600, // Semibold
                    ),
                    maxLines: 1, // Changed: Limit name to single line
                    overflow: TextOverflow.ellipsis,
                  ),
                  // REMOVED: Redundant Arabic name display

                  // ADDED: Display Active Ingredient
                  if (drug.active.isNotEmpty)
                    Padding(
                      padding: AppSpacing.edgeInsetsVXXSmall, // pt-0.5 (2px)
                      child: Text(
                        drug.active, // Display English active ingredient
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(
                            0.8,
                          ), // Muted slightly more
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection:
                            ui
                                .TextDirection
                                .ltr, // Ensure LTR for English text using alias
                      ),
                    ),

                  AppSpacing.gapVSmall, // mt-2 (8px)
                  // --- Dosage Form ---
                  if (dosageString.isNotEmpty)
                    Text(
                      dosageString,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant, // Muted
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  AppSpacing.gapVMedium, // mt-3 (12px)
                  // --- Badges and Price ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment.end, // Align price/badges to bottom
                    children: [
                      // --- Category / Alternative Badges ---
                      Flexible(
                        // Allow badges to wrap if needed
                        child: Wrap(
                          spacing: AppSpacing.xsmall, // gap-1 (4px)
                          runSpacing: AppSpacing.xsmall,
                          children: [
                            if (drug.mainCategory.isNotEmpty)
                              CustomBadge(
                                label:
                                    kCategoryTranslation[drug.mainCategory] ??
                                    drug.mainCategory,
                                backgroundColor: colorScheme.secondaryContainer,
                                textColor: colorScheme.onSecondaryContainer,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.small, // px-2 (8px)
                                  vertical: AppSpacing.xxsmall, // py-0.5 (2px)
                                ),
                                // Removed textStyle parameter
                              ),
                            if (isAlternative)
                              CustomBadge(
                                label: 'بديل',
                                backgroundColor: colorScheme.primaryContainer,
                                textColor: colorScheme.onPrimaryContainer,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.small, // px-2 (8px)
                                  vertical: AppSpacing.xxsmall, // py-0.5 (2px)
                                ),
                                // Removed textStyle parameter
                              ),
                          ],
                        ),
                      ),

                      AppSpacing.gapHSmall, // Add horizontal space
                      // --- Price and Popular Icon ---
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .center, // Center price and icon vertically
                        children: [
                          // Price Change Badge (Optional)
                          if (isPriceChanged)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSpacing.xsmall, // me-1 (4px)
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
                                  horizontal: AppSpacing.xsmall, // px-1 (4px)
                                  vertical: 1.0, // py-px
                                ),
                                // Removed textStyle parameter
                              ),
                            ),
                          // Price
                          Text(
                            '${_formatPrice(drug.price)} L.E', // Changed currency symbol
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold, // Bold
                              color: colorScheme.primary, // Highlight price
                            ),
                          ),
                          // Old Price (Added)
                          if (drug.oldPrice != null &&
                              drug.oldPrice!.isNotEmpty &&
                              isPriceChanged)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: AppSpacing.xsmall, // Add space
                              ),
                              child: Text(
                                '${_formatPrice(drug.oldPrice!)} L.E',
                                style: textTheme.labelSmall?.copyWith(
                                  // Use smaller style
                                  color: colorScheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          // Popular Icon
                          if (isPopular)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: AppSpacing.xsmall, // ms-1 (4px)
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
    );
  }

  // --- Thumbnail Card Implementation (Adjusted for Consistency) ---
  Widget _buildThumbnailCard(BuildContext context) {
    _logger.v(
      "DrugCard _buildThumbnailCard: drug=${drug.tradeName}",
    ); // Keep original log
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final displayName =
        (isArabic && drug.arabicName.isNotEmpty)
            ? drug.arabicName
            : drug.tradeName;

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
        isPriceChanged && oldPriceValue != null && oldPriceValue != 0
            ? ((currentPriceValue! - oldPriceValue) / oldPriceValue * 100).abs()
            : 0;

    return SizedBox(
      width: 280, // Corrected: Increased width as requested
      child: Card(
        // Using Card properties defined in main.dart theme
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            AppSpacing.medium,
          ), // Match theme card radius (12)
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Optional: Top highlight bar
                  // Container( height: AppSpacing.xsmall, ... ),
                  Padding(
                    padding: AppSpacing.edgeInsetsAllMedium, // p-3 (12px)
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reserve space for top-right icons/badges
                        const SizedBox(
                          height: AppSpacing.large,
                        ), // Approx 16px for icon/badge space
                        // --- Drug Name (Localized) ---
                        Text(
                          displayName, // Use localized name
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500, // Medium weight
                          ),
                          maxLines: 1, // Changed: Limit name to single line
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),
                        // ADDED: Display Active Ingredient in Thumbnail
                        if (drug.active.isNotEmpty)
                          Padding(
                            padding:
                                AppSpacing.edgeInsetsVXXSmall, // pt-0.5 (2px)
                            child: Text(
                              drug.active,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withOpacity(
                                  0.8,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: ui.TextDirection.ltr, // Ensure LTR
                            ),
                          ),
                        AppSpacing.gapVXSmall, // mt-1 (4px)
                        // Changed: Use Row for prices
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .baseline, // Align text baselines
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${_formatPrice(drug.price)} L.E', // Changed currency symbol
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600, // Semibold
                                color: colorScheme.primary,
                              ),
                            ),
                            if (drug.oldPrice != null &&
                                drug.oldPrice!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: AppSpacing.xsmall,
                                ), // Add space between prices
                                child: Text(
                                  '${_formatPrice(drug.oldPrice!)} L.E', // Changed currency symbol
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Removed extra space at bottom - Positioned badge handles its own spacing
                      ],
                    ),
                  ),
                ],
              ),
              // --- Price Change Badge (Bottom Left) ---
              if (isPriceChanged)
                Positioned.directional(
                  textDirection: Directionality.of(
                    context,
                  ), // Use context's direction
                  bottom: AppSpacing.medium, // bottom-3 (12px)
                  end: // Use 'end' instead of 'start'
                      AppSpacing.medium, // end-3 (12px) - Adapts to LTR/RTL
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
                    iconSize: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xsmall, // px-1 (4px)
                      vertical: 1.0, // py-px
                    ),
                    // Removed textStyle parameter
                  ),
                ),
              // --- Popular Icon (Top Right) ---
              if (isPopular)
                Positioned(
                  top: AppSpacing.small, // top-2 (8px)
                  right: AppSpacing.small, // right-2 (8px)
                  child: Icon(
                    LucideIcons.star,
                    size: 16,
                    color: Colors.amber.shade600,
                    semanticLabel: 'دواء شائع',
                  ),
                ),
              // --- Alternative Badge (Top Right, if not popular) ---
              if (isAlternative && !isPopular)
                Positioned(
                  top: AppSpacing.small, // top-2 (8px)
                  right: AppSpacing.small, // right-2 (8px)
                  child: CustomBadge(
                    label: 'بديل',
                    backgroundColor: colorScheme.primaryContainer,
                    textColor: colorScheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xsmall, // px-1 (4px)
                      vertical: 1.0, // py-px
                    ),
                    // Removed textStyle parameter
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
