// Import logger first
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import 'dart:ui' as ui; // Explicitly import dart:ui with alias

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:lucide_icons/lucide_icons.dart'; // Use Lucide Icons
import '../../domain/entities/drug_entity.dart';
import '../widgets/custom_badge.dart'; // Import CustomBadge
import '../../domain/repositories/interaction_repository.dart'; // Import InteractionRepository
import '../../core/utils/currency_helper.dart'; // Import currency helper

enum DrugCardType { thumbnail, detailed }

class DrugCard extends StatelessWidget {
  final FileLoggerService _logger = locator<FileLoggerService>();
  final InteractionRepository _interactionRepository =
      locator<InteractionRepository>();
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
      String concentrationStr = drug.concentration.toStringAsFixed(
        drug.concentration.truncateToDouble() == drug.concentration ? 0 : 1,
      );
      dosage += ' $concentrationStr ${drug.unit}';
    }
    return dosage.trim();
  }

  // Helper to get time since update
  String _getTimeSinceUpdate(BuildContext context, String dateString) {
    if (dateString.isEmpty) return '';

    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    try {
      DateTime? updateDate;
      if (dateString.contains('-')) {
        updateDate = DateTime.tryParse(dateString);
      } else if (dateString.contains('/')) {
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

      // Simple relative time format
      if (difference.inDays == 0) {
        return isArabic ? 'اليوم' : 'Today';
      } else if (difference.inDays == 1) {
        return isArabic ? 'أمس' : 'Yesterday';
      } else if (difference.inDays < 30) {
        return isArabic
            ? 'منذ ${difference.inDays} يوم'
            : '${difference.inDays}d ago';
      } else {
        return DateFormat('dd/MM/yyyy', locale.languageCode).format(updateDate);
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return type == DrugCardType.thumbnail
        ? _buildThumbnailCard(context)
        : _buildDetailedCard(context);
  }

  // --- Detailed Card Implementation ---
  Widget _buildDetailedCard(BuildContext context) {
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

    final bool hasInteractions = _interactionRepository.hasKnownInteractions(
      drug,
    );
    final String updateTime = _getTimeSinceUpdate(
      context,
      drug.lastPriceUpdate,
    );

    return Container(
      // Ensure minimum height constraint as requested for consistency
      constraints: const BoxConstraints(minHeight: 110),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header: Name + Interaction Warning (Top Right/Left)
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
                            ),
                          ),
                          // Interaction Warning at TOP
                          if (hasInteractions)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 6,
                              ),
                              child: Tooltip(
                                message:
                                    isArabic
                                        ? 'يوجد تفاعلات دوائية'
                                        : 'Has Interactions',
                                child: Icon(
                                  LucideIcons.alertTriangle,
                                  size: 16,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Active Ingredient
                      if (drug.active.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            drug.active,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: ui.TextDirection.ltr,
                          ),
                        ),

                      const Spacer(),

                      // Price Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatPrice(drug.price),
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color:
                                  isPriceChanged
                                      ? (isPriceIncreased
                                          ? Colors.red.shade700
                                          : Colors.green.shade700)
                                      : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            CurrencyHelper.getCurrencySymbol(context),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          // Price Change Badge
                          if (isPriceChanged) ...[
                            const SizedBox(width: 8),
                            // Calculate percentage strictly for display
                            Builder(
                              builder: (ctx) {
                                final double diff =
                                    currentPriceValue! - oldPriceValue!;
                                final double pct =
                                    oldPriceValue > 0
                                        ? ((diff / oldPriceValue) * 100).abs()
                                        : 0;
                                return Container(
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
                                    '${isPriceIncreased ? '+' : '-'}${pct.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color:
                                          isPriceIncreased
                                              ? Colors.red.shade800
                                              : Colors.green.shade800,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right Side: Badges & Update Time (Bottom aligned)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end, // Align to bottom
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Type Badge
                    if (isPopular || isAlternative)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: CustomBadge(
                          label:
                              isPopular
                                  ? (isArabic ? 'شائع' : 'Popular')
                                  : (isArabic ? 'بديل' : 'Alt'),
                          backgroundColor:
                              isPopular
                                  ? Colors.amber.shade100
                                  : colorScheme.primaryContainer,
                          textColor:
                              isPopular
                                  ? Colors.amber.shade800
                                  : colorScheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),

                    // NEW Badge (Only for new items)
                    if (drug.oldPrice == null && drug.id != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isArabic ? 'جديد' : 'NEW',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    // Update Duration Badge (Green & Bold)
                    if (updateTime.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? Colors.green.shade900.withValues(alpha: 0.3)
                                  : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                isDark
                                    ? Colors.green.shade700
                                    : Colors.green.shade200,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          updateTime,
                          style: TextStyle(
                            color:
                                isDark
                                    ? Colors.green.shade300
                                    : Colors.green.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.w800, // Bold
                          ),
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

  // --- Thumbnail Card Implementation ---
  Widget _buildThumbnailCard(BuildContext context) {
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

    return SizedBox(
      width: 180,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayName,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (drug.active.isNotEmpty)
                    Text(
                      drug.active,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: ui.TextDirection.ltr,
                    ),

                  const SizedBox(height: 8),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatPrice(drug.price),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color:
                              isPriceChanged
                                  ? (isPriceIncreased
                                      ? Colors.red.shade700
                                      : Colors.green.shade700)
                                  : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        CurrencyHelper.getCurrencySymbol(context),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontSize: 10,
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
