import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/app_spacing.dart';
import 'package:mediswitch/data/models/dosage_guidelines_model.dart'; // Import DosageGuidelinesModel
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/presentation/bloc/interaction_provider.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/widgets/cards/interaction_card.dart';
import 'package:mediswitch/presentation/widgets/cards/modern_drug_card.dart';
import 'package:mediswitch/presentation/widgets/modern_badge.dart';
import 'package:provider/provider.dart';

class DrugDetailsScreen extends StatefulWidget {
  final DrugEntity drug;
  // ... (skipunchanged)

  final VoidCallback? onBack;

  const DrugDetailsScreen({super.key, required this.drug, this.onBack});

  @override
  State<DrugDetailsScreen> createState() => _DrugDetailsScreenState();
}

class _DrugDetailsScreenState extends State<DrugDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } on FormatException catch (_) {
      return dateStr; // Return original if parsing fails
    } catch (e) {
      return dateStr;
    }
  }

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
        'id': 'similarities',
        'label': isRTL ? 'المثائل' : 'Similarities',
        'icon': LucideIcons.gitCompare,
      },
      {
        'id': 'alternatives',
        'label': l10n.alternativesTab,
        'icon': LucideIcons.repeat,
      },
      {
        'id': 'interactions',
        'label': l10n.interactionsTab,
        'icon': LucideIcons.alertTriangle,
      },
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          _buildHeader(context, isRTL, colorScheme),
          // TabBar with proper padding (px-4 py-3)
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              indicatorColor: colorScheme.primary,
              indicatorWeight: 2,
              labelColor: colorScheme.primary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs:
                  tabs.map((tab) {
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab['icon'] as IconData, size: 16),
                          const SizedBox(width: 6),
                          Text(tab['label'] as String),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
          // TabBarView with swipe support
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(isRTL, theme, l10n, colorScheme),
                _buildDosageTab(theme, l10n),
                _buildSimilaritiesTab(isRTL, l10n, colorScheme),
                _buildAlternativesTab(isRTL, l10n, colorScheme),
                _buildInteractionsTab(isRTL, colorScheme),
              ],
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
    final double? currentPrice = double.tryParse(widget.drug.price);
    final double? oldPrice =
        widget.drug.oldPrice != null
            ? double.tryParse(widget.drug.oldPrice!)
            : null;

    if (currentPrice != null && oldPrice != null && oldPrice > 0) {
      priceChange = ((currentPrice - oldPrice) / oldPrice) * 100;
    }

    return Container(
      decoration: BoxDecoration(color: colorScheme.primary),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.large,
                vertical: AppSpacing.medium,
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
                      backgroundColor: colorScheme.onPrimary.withValues(
                        alpha: 0.1,
                      ),
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
                          backgroundColor: colorScheme.onPrimary.withValues(
                            alpha: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
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
                                      : colorScheme.onPrimary.withValues(
                                        alpha: 0.1,
                                      ),
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
                AppSpacing.large,
                AppSpacing.small,
                AppSpacing.large,
                AppSpacing.xxlarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drug name without icon
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.drug.tradeName,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.drug.arabicName,
                        style: TextStyle(
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    widget.drug.company,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${currentPrice?.toStringAsFixed(2) ?? widget.drug.price} '
                        'EGP',

                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      if (oldPrice != null)
                        Text(
                          oldPrice.toStringAsFixed(2),
                          style: TextStyle(
                            color: colorScheme.onPrimary.withValues(alpha: 0.6),
                            decoration: TextDecoration.lineThrough,
                            fontSize: 18,
                          ),
                        ),
                      const SizedBox(width: AppSpacing.small),
                      if (priceChange != 0)
                        ModernBadge(
                          text: '${priceChange.abs().toStringAsFixed(0)}%',
                          variant:
                              priceChange < 0
                                  ? BadgeVariant.priceDown
                                  : BadgeVariant.priceUp,
                          size: BadgeSize.md,
                        ),
                    ],
                  ),
                  // Last Updated Date
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.refreshCw,
                        size: 14,
                        color: colorScheme.onPrimary.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Updated ${_formatDate(widget.drug.lastPriceUpdate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimary.withValues(alpha: 0.6),
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

  // ====== Individual Tab Builders for TabBarView ======

  Widget _buildInfoTab(
    bool isRTL,
    ThemeData theme,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      padding: AppSpacing.edgeInsetsAllLarge,
      child:
          Column(
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
                title: l10n.infoTab,
                colorScheme: colorScheme,
                child: Column(
                  children: [
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
          ).animate().fadeIn(),
    );
  }

  Widget _buildDosageTab(ThemeData theme, AppLocalizations l10n) {
    final appColors = theme.appColors;
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: AppSpacing.edgeInsetsAllLarge,
      child:
          FutureBuilder<List<DosageGuidelinesModel>>(
            future: Provider.of<MedicineProvider>(
              context,
              listen: false,
            ).getDosageGuidelines(widget.drug.active),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final guidelines = snapshot.data ?? [];

              DosageGuidelinesModel? bestMatch;

              if (guidelines.isNotEmpty) {
                try {
                  bestMatch = guidelines.firstWhere((g) {
                    if (g.strength == null) return false;
                    final drugStr =
                        '${widget.drug.concentration} ${widget.drug.unit}'
                            .toLowerCase()
                            .replaceAll(' ', '');
                    final guidelineStr = g.strength!.toLowerCase().replaceAll(
                      ' ',
                      '',
                    );
                    return guidelineStr.contains(drugStr) ||
                        drugStr.contains(guidelineStr);
                  });
                } catch (e) {
                  bestMatch = guidelines.first;
                }
              }

              final standardDose =
                  bestMatch?.standardDose ??
                  (widget.drug.usage.isNotEmpty
                      ? widget.drug.usage
                      : 'Consult your doctor');
              final instructions =
                  bestMatch?.packageLabel ??
                  'Always read the leaflet and consult your healthcare provider for specific instructions.';
              final strengthDisplay =
                  bestMatch?.strength ??
                  '${widget.drug.concentration} ${widget.drug.unit}';
              final maxDose = bestMatch?.maxDose;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: appColors.shadowCard,
                      border: Border.all(
                        color: appColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.droplets,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Strength',
                                  style: TextStyle(
                                    color: appColors.mutedForeground,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  strengthDisplay,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                LucideIcons.clock,
                                size: 20,
                                color: appColors.mutedForeground,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Standard Dose',
                                    style: TextStyle(
                                      color: appColors.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    standardDose,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (maxDose != null && maxDose.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  LucideIcons.alertCircle,
                                  size: 20,
                                  color: appColors.dangerForeground,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Max Daily Dose',
                                      style: TextStyle(
                                        color: appColors.mutedForeground,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      maxDose,
                                      style: TextStyle(
                                        color: appColors.dangerForeground,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.concentration,
                          style: TextStyle(
                            color: appColors.mutedForeground,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${widget.drug.concentration} ${widget.drug.unit}',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appColors.warningSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: appColors.warningSoft.withValues(alpha: 1.0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.alertTriangle,
                              size: 16,
                              color: appColors.warningForeground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Instructions',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: appColors.warningForeground,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          instructions,
                          style: TextStyle(
                            color: appColors.warningForeground.withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ).animate().fadeIn(),
    );
  }

  Widget _buildSimilaritiesTab(
    bool isRTL,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return FutureBuilder<List<DrugEntity>>(
      future: Provider.of<MedicineProvider>(
        context,
        listen: false,
      ).getSimilarDrugs(widget.drug),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading similars',
              style: TextStyle(color: colorScheme.error),
            ),
          );
        }

        final similars = snapshot.data ?? [];

        if (similars.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.package,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSimilarsFound,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: similars.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final drug = similars[index];
            final isFav = Provider.of<MedicineProvider>(
              context,
              listen: false,
            ).isFavorite(drug);

            return ModernDrugCard(
              drug: drug,
              isFavorite: isFav,
              onFavoriteToggle:
                  () => Provider.of<MedicineProvider>(
                    context,
                    listen: false,
                  ).toggleFavorite(drug),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DrugDetailsScreen(drug: drug),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAlternativesTab(
    bool isRTL,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return FutureBuilder<List<DrugEntity>>(
      future: Provider.of<MedicineProvider>(
        context,
        listen: false,
      ).getAlternativeDrugs(widget.drug),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading alternatives',
              style: TextStyle(color: colorScheme.error),
            ),
          );
        }

        final alternatives = snapshot.data ?? [];

        if (alternatives.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.package,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noAlternativesFoundMsg,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: alternatives.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final drug = alternatives[index];
            final isFav = Provider.of<MedicineProvider>(
              context,
              listen: false,
            ).isFavorite(drug);

            return ModernDrugCard(
              drug: drug,
              isFavorite: isFav,
              onFavoriteToggle:
                  () => Provider.of<MedicineProvider>(
                    context,
                    listen: false,
                  ).toggleFavorite(drug),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DrugDetailsScreen(drug: drug),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInteractionsTab(bool isRTL, ColorScheme colorScheme) {
    return FutureBuilder<List<DrugInteraction>>(
      future: Provider.of<InteractionProvider>(
        context,
        listen: false,
      ).getDrugInteractions(widget.drug),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.alertCircle,
                    size: 48,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading interactions',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
              ),
            ),
          );
        }

        final interactions = snapshot.data ?? [];

        if (interactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.shieldCheck,
                      size: 32,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isRTL ? 'لا توجد تفاعلات معروفة' : 'No Known Interactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRTL
                        ? 'هذا الدواء آمن بناءً على البيانات المتاحة'
                        : 'This drug appears safe based on available data',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final sortedInteractions = List<DrugInteraction>.from(interactions);
        sortedInteractions.sort((a, b) {
          const order = {
            InteractionSeverity.contraindicated: 0,
            InteractionSeverity.severe: 1,
            InteractionSeverity.major: 2,
            InteractionSeverity.moderate: 3,
            InteractionSeverity.minor: 4,
            InteractionSeverity.unknown: 5,
          };
          return (order[a.severity] ?? 5).compareTo(order[b.severity] ?? 5);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sortedInteractions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return InteractionCard(interaction: sortedInteractions[index]);
          },
        );
      },
    );
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
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
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
              color: Theme.of(context).appColors.accent.withValues(alpha: 0.2),
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
}
