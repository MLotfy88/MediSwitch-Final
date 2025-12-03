// Import logger first
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import 'dart:ui' as ui; // Explicitly import dart:ui with alias

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:lucide_icons/lucide_icons.dart'; // Use Lucide Icons
import '../../domain/entities/drug_entity.dart';
import '../widgets/custom_badge.dart'; // Import CustomBadge
import '../../core/constants/app_constants.dart'; // Import the constants file
import '../../core/constants/app_spacing.dart'; // Import spacing constants
import '../../domain/repositories/interaction_repository.dart'; // Import InteractionRepository

enum DrugCardType { thumbnail, detailed }

class DrugCard extends StatelessWidget {
  final FileLoggerService _logger =
      locator<FileLoggerService>(); // Add logger instance
  final InteractionRepository _interactionRepository = locator<InteractionRepository>(); // Inject repo
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

  // --- Detailed Card Implementation (Redesigned 2.0) ---
  Widget _buildDetailedCard(BuildContext context) {
    _logger.v(
      "DrugCard _buildDetailedCard: drug=${drug.tradeName}",
    );
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final displayName =
        (isArabic && drug.arabicName.isNotEmpty)
            ? drug.arabicName
            : drug.tradeName;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

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

    final bool hasInteractions = _interactionRepository.hasKnownInteractions(drug);

    // --- NEW DESIGN: Container with Gradient & Colored Shadow ---
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.medium), // 12px
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.cardColor,
            isDark
                ? theme.cardColor.withOpacity(0.8) // Subtle gradient in dark
                : theme.colorScheme.surface, // Slight off-white in light
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: isDark
            ? Border.all(color: colorScheme.outline.withOpacity(0.1))
            : null, // Subtle border in dark mode
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.medium),
          child: Padding(
            padding: AppSpacing.edgeInsetsAllLarge, // 16px
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Content ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Name & Active Ingredient ---
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasInteractions)
                            Tooltip(
                              message: 'يوجد تفاعلات دوائية مسجلة',
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(start: 4),
                                child: Icon(
                                  LucideIcons.alertTriangle,
                                fontSize: 20,
                                color: isPriceChanged
                                    ? (isPriceIncreased
                                        ? Colors.red.shade700
                                        : Colors.green.shade700)
                                    : colorScheme.onSurface,
                              ),
                            ),
                            AppSpacing.gapHXXSmall,
                            Text(
                              'ج.م',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            // Price trend indicator
                            if (isPriceChanged) ...[
                              AppSpacing.gapHSmall,
                              Icon(
                                isPriceIncreased
                                    ? LucideIcons.trendingUp
                                    : LucideIcons.trendingDown,
                                size: 16,
                                color: isPriceIncreased
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                              ),
                            ],
                          ],
                        ),
                        // Old price (if changed)
                        if (isPriceChanged && oldPriceValue != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Text(
                                  'كان: ',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${_formatPrice(drug.oldPrice!)} ج.م',
                                  style: textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                AppSpacing.gapVMedium,

                // --- Last Update Date & Badges ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Last Update Date ---
                    if (drug.lastPriceUpdate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 12,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'آخر تحديث: ${drug.lastPriceUpdate}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // --- Badges Row: Dosage Form + Extras ---
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small / 2,
                      children: [
                        // Dosage Form Badge
                        if (dosageString.isNotEmpty)
                          CustomBadge(
                            label: dosageString,
                            backgroundColor: colorScheme.secondaryContainer,
                            textColor: colorScheme.onSecondaryContainer,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.small,
                              vertical: 4,
                            ),
                          ),
                        if (isPopular)
                          CustomBadge(
                            label: 'شائع',
                            backgroundColor: Colors.amber.shade100,
                            textColor: Colors.amber.shade800,
                            icon: LucideIcons.star,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.small,
                              vertical: 4,
                            ),
                          ),
                        if (isAlternative)
                          CustomBadge(
                            label: 'بديل',
                            backgroundColor: colorScheme.primaryContainer,
                            textColor: colorScheme.onPrimaryContainer,
                            icon: LucideIcons.replace,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.small,
                              vertical: 4,
                            ),
                          ),
                      ],
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

  // --- Thumbnail Card Implementation (Redesigned 2.0) ---
  Widget _buildThumbnailCard(BuildContext context) {
    _logger.v(
      "DrugCard _buildThumbnailCard: drug=${drug.tradeName}",
    );
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final displayName =
        (isArabic && drug.arabicName.isNotEmpty)
            ? drug.arabicName
            : drug.tradeName;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

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
      width: 200, // Increased width from 160 to 200 for more content
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.medium),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.cardColor,
              isDark
                  ? theme.cardColor.withOpacity(0.8)
                  : theme.colorScheme.surface,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
          border: isDark
              ? Border.all(color: colorScheme.outline.withOpacity(0.1))
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.medium),
            child: Padding(
              padding: const EdgeInsets.all(14), // Increased padding from 12 to 14
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Text(
                    displayName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                  ),
                  
                  // --- Active Ingredient ---
                  if (drug.active.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        drug.active,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: ui.TextDirection.ltr,
                      ),
                    ),
                    
                    
                  // --- Price Section ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_formatPrice(drug.price)}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isPriceChanged
                                  ? (isPriceIncreased
                                      ? Colors.red.shade700
                                      : Colors.green.shade700)
                                  : colorScheme.primary,
                            ),
                            textDirection: ui.TextDirection.ltr,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ج.م',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                          // Price trend indicator
                          if (isPriceChanged) ...[
                            const SizedBox(width: 4),
                            Icon(
                              isPriceIncreased
                                  ? LucideIcons.trendingUp
                                  : LucideIcons.trendingDown,
                              size: 13,
                              color: isPriceIncreased
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                          ],
                        ],
                      ),
                      // Old price
                      if (isPriceChanged && oldPriceValue != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'كان: ${_formatPrice(drug.oldPrice!)} ج.م',
                            style: textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                              fontSize: 9,
                            ),
                          ),
                        ),
                      // Update date
                      if (drug.lastPriceUpdate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 10,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  drug.lastPriceUpdate,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                    fontSize: 9,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
      ),
    );
  }
}
