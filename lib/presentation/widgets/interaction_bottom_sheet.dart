import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';

class InteractionBottomSheet extends StatelessWidget {
  final DrugInteraction interaction;

  const InteractionBottomSheet({super.key, required this.interaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final isFood =
        interaction.type == 'food' ||
        interaction.ingredient2.toLowerCase().contains('food') ||
        interaction.ingredient2.toLowerCase().contains('diet');

    final headerColor = isFood ? Colors.orange : AppColors.danger;
    final headerIcon =
        isFood ? LucideIcons.utensils : LucideIcons.alertTriangle;
    final headerTitle =
        isFood
            ? (isRTL ? 'تفاعل غذائي' : 'Food Interaction')
            : (isRTL ? 'تفاعل دوائي' : 'Drug Interaction');

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 2. Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: headerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(headerIcon, color: headerColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headerTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: headerColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isRTL
                            ? 'تفاصيل التفاعل والخطورة'
                            : 'Details & Severity',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x, size: 20),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // 3. Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ingredients
                  _DetailBox(
                    isRTL: isRTL,
                    theme: theme,
                    label: isRTL ? 'أطراف التفاعل' : 'Interacting Agents',
                    content1: interaction.ingredient1,
                    content2: interaction.ingredient2,
                    isFood: isFood,
                  ),

                  const SizedBox(height: 20),

                  // Severity
                  _DetailRow(
                    label: isRTL ? 'مستوى الخطورة' : 'Severity Level',
                    value: interaction.severity,
                    isSeverity: true,
                    isLarge: true,
                  ),

                  const SizedBox(height: 24),

                  // Effect / Description
                  Text(
                    isRTL
                        ? 'التأثير الطبي / الوصف:'
                        : 'Clinical Effect / Description:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      interaction.effect ??
                          (isRTL
                              ? 'لا توجد تفاصيل إضافية متاحة'
                              : 'No additional details available'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Footer Button (Close)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                isRTL ? 'حسناً، فهمت' : 'Got it',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  final bool isRTL;
  final ThemeData theme;
  final String label;
  final String content1;
  final String content2;
  final bool isFood;

  const _DetailBox({
    required this.isRTL,
    required this.theme,
    required this.label,
    required this.content1,
    required this.content2,
    required this.isFood,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _IngredientChip(
                name: content1,
                theme: theme,
                isFood: false,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                isFood
                    ? LucideIcons.utensilsCrossed
                    : LucideIcons.arrowRightLeft,
                size: 20,
                color: theme.colorScheme.outline,
              ),
            ),
            Expanded(
              child: _IngredientChip(
                name: content2,
                theme: theme,
                isFood: isFood,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IngredientChip extends StatelessWidget {
  final String name;
  final ThemeData theme;
  final bool isFood;

  const _IngredientChip({
    required this.name,
    required this.theme,
    required this.isFood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:
            isFood ? Colors.orange.withOpacity(0.1) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isFood
                  ? Colors.orange.withOpacity(0.3)
                  : theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isFood) ...[
            const Icon(LucideIcons.apple, size: 14, color: Colors.orange),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color:
                    isFood ? Colors.orange[800] : theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isSeverity;
  final bool isLarge;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isSeverity = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLarge) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              isSeverity &&
                      (value.toLowerCase().contains('severe') ||
                          value.toLowerCase().contains('major') ||
                          value.toLowerCase().contains('contraindicated'))
                  ? AppColors.danger.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSeverity &&
                        (value.toLowerCase().contains('severe') ||
                            value.toLowerCase().contains('major') ||
                            value.toLowerCase().contains('contraindicated'))
                    ? AppColors.danger.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color:
                    isSeverity &&
                            (value.toLowerCase().contains('severe') ||
                                value.toLowerCase().contains('major') ||
                                value.toLowerCase().contains('contraindicated'))
                        ? AppColors.danger
                        : AppColors.primary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color:
                    isSeverity &&
                            (value.toLowerCase().contains('severe') ||
                                value.toLowerCase().contains('major'))
                        ? AppColors.danger
                        : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
