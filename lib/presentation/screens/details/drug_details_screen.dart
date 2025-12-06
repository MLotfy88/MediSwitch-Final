import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mediswitch/core/constants/design_tokens.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/widgets/home/drug_card.dart';

import 'package:provider/provider.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';

// Assuming DrugUIModel is shared or redefined here.
// Ideally should be in a shared models directory.
// For now, reusing the one defined in drug_card.dart or redefining simpler version for this screen.

class DrugDetailsScreen extends StatefulWidget {
  final DrugEntity drug;
  final VoidCallback? onBack;

  const DrugDetailsScreen({super.key, required this.drug, this.onBack});

  @override
  State<DrugDetailsScreen> createState() => _DrugDetailsScreenState();
}

class _DrugDetailsScreenState extends State<DrugDetailsScreen> {
  String activeTab = 'info';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = l10n.localeName == 'ar';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final tabs = [
      {'id': 'info', 'label': l10n.infoTab, 'icon': LucideIcons.info},
      {'id': 'dosage', 'label': l10n.dosageTab, 'icon': LucideIcons.droplets},
      {
        'id': 'alternatives',
        'label': l10n.alternativesTab,
        'icon': LucideIcons.gitCompare,
      },
      {
        'id': 'interactions',
        'label': l10n.interactionsTab,
        'icon': LucideIcons.alertTriangle,
      },
      {'id': 'price', 'label': l10n.priceTab, 'icon': LucideIcons.trendingDown},
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(context, isRTL, colorScheme),
          _buildTabs(tabs, colorScheme),
          Expanded(
            child: SingleChildScrollView(
              padding: AppSpacing.paddingLG,
              child: _buildTabContent(isRTL, colorScheme, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isRTL,
    ColorScheme colorScheme,
  ) {
    double priceChange = 0;
    double? currentPrice = double.tryParse(widget.drug.price);
    double? oldPrice =
        widget.drug.oldPrice != null
            ? double.tryParse(widget.drug.oldPrice!)
            : null;

    if (currentPrice != null && oldPrice != null && oldPrice > 0) {
      priceChange = ((currentPrice - oldPrice) / oldPrice) * 100;
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary, // Use theme primary
        // Optional: Add gradient if desired, but solid primary is safer for dark/light adaptation unless we define gradients in theme
        // gradient: LinearGradient(...)
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).pop(),
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: colorScheme.onPrimary,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.onPrimary.withOpacity(0.1),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          LucideIcons.share2,
                          color: colorScheme.onPrimary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.onPrimary.withOpacity(
                            0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Consumer<MedicineProvider>(
                        builder: (context, provider, _) {
                          final isFav = provider.isFavorite(widget.drug);
                          return IconButton(
                            onPressed:
                                () => provider.toggleFavorite(widget.drug),
                            icon: Icon(
                              LucideIcons.heart,
                              color:
                                  isFav
                                      ? Theme.of(context).colorScheme.error
                                      : colorScheme.onPrimary,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  isFav
                                      ? colorScheme.surface
                                      : colorScheme.onPrimary.withOpacity(0.1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withOpacity(0.1),
                          borderRadius: AppRadius.circularLg,
                        ),
                        child: Icon(
                          LucideIcons.pill,
                          color: colorScheme.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.drug.tradeName,
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                // Popular badge logic removed as not in entity yet
                              ],
                            ),
                            Text(
                              widget.drug.arabicName,
                              style: TextStyle(
                                color: colorScheme.onPrimary.withOpacity(0.8),
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.drug.company,
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${currentPrice?.toStringAsFixed(2) ?? widget.drug.price} EGP',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      if (oldPrice != null)
                        Text(
                          oldPrice.toStringAsFixed(2),
                          style: TextStyle(
                            color: colorScheme.onPrimary.withOpacity(0.6),
                            decoration: TextDecoration.lineThrough,
                            fontSize: 18,
                          ),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      if (priceChange != 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).appColors.successSoft.withOpacity(
                              0.2,
                            ), // Keep semantic colors or add to theme
                            borderRadius: AppRadius.circularSm,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trendingDown,
                                color: Theme.of(context).appColors.successSoft,
                                size: 12,
                              ),
                              Text(
                                '${priceChange.abs().toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color:
                                      Theme.of(context).appColors.successSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(List<Map<String, dynamic>> tabs, ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surface,
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children:
              tabs.map((tab) {
                final isActive = activeTab == tab['id'];
                return GestureDetector(
                  onTap: () => setState(() => activeTab = tab['id'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              isActive
                                  ? colorScheme.primary
                                  : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          tab['icon'] as IconData,
                          size: 16,
                          color:
                              isActive
                                  ? colorScheme.primary
                                  : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tab['label'] as String,
                          style: TextStyle(
                            color:
                                isActive
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    bool isRTL,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    switch (activeTab) {
      case 'info':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              title: l10n.descriptionTitle,
              colorScheme: colorScheme,
              child: Text(
                widget.drug.description.isNotEmpty
                    ? widget.drug.description
                    : 'No description available.',
                style: TextStyle(
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: l10n.infoTab, // Reusing generic title
              colorScheme: colorScheme,
              child: Column(
                children: [
                  // Registration Number not in entity
                  _buildDetailRow(
                    LucideIcons.flaskConical,
                    'Active Ingredient',
                    widget.drug.active,
                    colorScheme,
                  ),
                  _buildDetailRow(
                    LucideIcons.building,
                    l10n.companyLabel.replaceAll(':', ''),
                    widget.drug.company,
                    colorScheme,
                  ),
                  _buildDetailRow(
                    LucideIcons.tablets,
                    l10n.formLabel.replaceAll(':', ''),
                    widget.drug.dosageForm,
                    colorScheme,
                  ),
                  _buildDetailRow(
                    LucideIcons.scale,
                    'Concentration',
                    '${widget.drug.concentration} ${widget.drug.unit}',
                    colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn();

      case 'dosage':
        return Column(
          children: [
            _buildCard(
              title: l10n.dosageTitle,
              colorScheme: colorScheme,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.pill,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.drug.concentration} ${widget.drug.unit}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Strength',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),
                  _buildDosageRow(
                    LucideIcons.clock,
                    'Usage',
                    widget.drug.usage,
                    colorScheme,
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn();

      case 'alternatives':
      case 'interactions':
      case 'price':
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(
                  LucideIcons.construction,
                  size: 48,
                  color: colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  "Feature coming soon",
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        );

      default:
        return Container();
    }
  }

  Widget _buildCard({
    required String title,
    required Widget child,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Was AppColors.card
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ], // Shadows might need adjustment for dark mode, but usually opacity handles it.
        border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).appColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDosageRow(
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
