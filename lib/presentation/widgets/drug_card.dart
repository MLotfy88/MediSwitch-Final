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
import '../../core/utils/currency_helper.dart'; // Import currency helper

enum DrugCardType { thumbnail, detailed }

class DrugCard extends StatelessWidget {
  final FileLoggerService _logger =
      locator<FileLoggerService>(); // Add logger instance
  final InteractionRepository _interactionRepository =
      locator<InteractionRepository>(); // Inject repo
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

  // Helper to get time since update (e.g., "منذ ساعتين")
  String _getTimeSinceUpdate(String dateString) {
    if (dateString.isEmpty) return '';

    try {
      DateTime? updateDate;
      // Try parsing yyyy-MM-dd first (new format)
      if (dateString.contains('-')) {
        updateDate = DateTime.tryParse(dateString);
      }
      // Fallback to dd/MM/yyyy (old format)
      else if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            updateDate = DateTime(year, month, day);
          }
        }
      }

      if (updateDate == null) return dateString;

      final now = DateTime.now();
      final difference = now.difference(updateDate);

      if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inDays < 7) {
        return 'منذ ${difference.inDays} يوم';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return 'منذ $weeks أسبوع';
      } else {
        // Return formatted date for older items
        return DateFormat('dd/MM/yyyy').format(updateDate);
      }
    } catch (e) {
      return dateString;
    }
  }

  // Helper to check if drug is new (updated within last 7 days)
  bool _isNewDrug(String dateString) {
    if (dateString.isEmpty) return false;

    try {
      DateTime? updateDate;
      // Try parsing yyyy-MM-dd first (new format)
      if (dateString.contains('-')) {
        updateDate = DateTime.tryParse(dateString);
      }
      // Fallback to dd/MM/yyyy (old format)
      else if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            updateDate = DateTime(year, month, day);
          }
        }
      }

      if (updateDate == null) return false;

      final now = DateTime.now();
      final difference = now.difference(updateDate);

      return difference.inDays <= 7;
    } catch (e) {
      return false;
    }
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

  // --- Detailed Card Implementation (Redesigned 2.1) ---
  Widget _buildDetailedCard(BuildContext context) {
    _logger.v("DrugCard _buildDetailedCard: drug=${drug.tradeName}");
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

    final bool hasInteractions = _interactionRepository.hasKnownInteractions(
      drug,
    );

    // --- NEW DESIGN: Solid Container with Border and Fixed Height ---
    return Container(
      constraints: const BoxConstraints(
        minHeight: 250, // Increased to prevent content overflow
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer, // Solid cleaner background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                height: 1.2,
                              ),
                              maxLines: 2, // Allow 2 lines for longer names
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasInteractions)
                            Tooltip(
                              message: 'يوجد تفاعلات دوائية مسجلة',
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 4,
                                ),
                                child: Icon(
                                  LucideIcons.alertTriangle,
                                  size: 16,
                                  color: Colors.amber.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (drug.active.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            drug.active,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary, // Primary color
                              fontSize: 13,
                              fontWeight: FontWeight.w600, // Bolder
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textDirection: ui.TextDirection.ltr,
                          ),
                        ),

                      const SizedBox(height: 8),

                      // --- Price Section with Old Price ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current Price
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'السعر الحالي',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${_formatPrice(drug.price)}',
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      color:
                                          isPriceChanged
                                              ? (isPriceIncreased
                                                  ? Colors.red.shade700
                                                  : Colors.green.shade700)
                                              : colorScheme
                                                  .onSurface, // High contrast
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    CurrencyHelper.getCurrencySymbol(context),
                                    style: textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  // Price percentage badge
                                  if (isPriceChanged &&
                                      priceChangePercentage > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isPriceIncreased
                                                ? Colors.red.shade100
                                                : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isPriceIncreased
                                                ? LucideIcons.trendingUp
                                                : LucideIcons.trendingDown,
                                            size: 11,
                                            color:
                                                isPriceIncreased
                                                    ? Colors.red.shade800
                                                    : Colors.green.shade800,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${isPriceIncreased ? '+' : '-'}${priceChangePercentage.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              color:
                                                  isPriceIncreased
                                                      ? Colors.red.shade800
                                                      : Colors.green.shade800,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              // Old price (if changed)
                              if (isPriceChanged && oldPriceValue != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Row(
                                    children: [
                                      Text(
                                        'كان: ',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant
                                              .withOpacity(0.7),
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        '${_formatPrice(drug.oldPrice!)} ${CurrencyHelper.getCurrencySymbol(context)}',
                                        style: textTheme.bodySmall?.copyWith(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: colorScheme.onSurfaceVariant
                                              .withOpacity(0.6),
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
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // --- Last Update Date & Badges ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end, // Align to end
                  children: [
                    // --- Last Update Date ---
                    if (drug.lastPriceUpdate.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _getTimeSinceUpdate(drug.lastPriceUpdate),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary, // More visible color
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    // --- Badges Row: Dosage Form + Extras ---
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small / 2,
                      alignment: WrapAlignment.end,
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

  // --- Thumbnail Card Implementation (Redesigned 2.1) ---
  Widget _buildThumbnailCard(BuildContext context) {
    _logger.v("DrugCard _buildThumbnailCard: drug=${drug.tradeName}");
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
      width: 240, // Increased width from 200 to 240
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer, // Solid cleaner background
          borderRadius: BorderRadius.circular(16), // Rounded-2xl
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name with NEW badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),
                      ),
                      if (_isNewDrug(drug.lastPriceUpdate))
                        Container(
                          margin: const EdgeInsetsDirectional.only(start: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'جديد',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // --- Active Ingredient ---
                  if (drug.active.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      child: Text(
                        drug.active,
                        style: textTheme.bodySmall?.copyWith(
                          color:
                              colorScheme
                                  .primary, // Changed to primary for visibility
                          fontSize: 12,
                          fontWeight: FontWeight.w600, // Bolder
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: ui.TextDirection.ltr,
                      ),
                    ),

                  const Spacer(), // Push price to bottom
                  // --- Price Section ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${_formatPrice(drug.price)}',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color:
                                  isPriceChanged
                                      ? (isPriceIncreased
                                          ? Colors.red.shade700
                                          : Colors.green.shade700)
                                      : colorScheme.onSurface, // High contrast
                            ),
                            textDirection: ui.TextDirection.ltr,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            CurrencyHelper.getCurrencySymbol(context),
                            style: textTheme.bodySmall?.copyWith(
                              color:
                                  colorScheme.onSurface, // Darker than variant
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Price Change Badge & Old Price
                      if (isPriceChanged)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              // Percentage Badge
                              if (priceChangePercentage > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isPriceIncreased
                                            ? Colors.red.shade100
                                            : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${isPriceIncreased ? '+' : '-'}${priceChangePercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color:
                                          isPriceIncreased
                                              ? Colors.red.shade800
                                              : Colors.green.shade800,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),

                              const SizedBox(width: 8),

                              // Old Price
                              if (oldPriceValue != null)
                                Text(
                                  '${_formatPrice(drug.oldPrice!)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),

                      // Update date
                      if (drug.lastPriceUpdate.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.clock,
                                size: 12,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _getTimeSinceUpdate(drug.lastPriceUpdate),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                    fontSize: 10,
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
