import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/app_spacing.dart';
import 'package:mediswitch/core/utils/date_formatter.dart';
import 'package:mediswitch/domain/entities/disease_interaction.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/presentation/bloc/interaction_provider.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/widgets/cards/interaction_card.dart';
import 'package:mediswitch/presentation/widgets/cards/modern_drug_card.dart';
import 'package:mediswitch/presentation/widgets/details/dosage_tab.dart';
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
    final hasDisease = widget.drug.hasDiseaseInteraction;
    _tabController = TabController(length: hasDisease ? 6 : 5, vsync: this);
    // Add to history once the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MedicineProvider>(
          context,
          listen: false,
        ).addToRecentlyViewed(widget.drug);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    if (widget.drug.hasDiseaseInteraction) {
      tabs.add({
        'id': 'disease_interactions',
        'label': isRTL ? 'تفاعلات الأمراض' : 'Disease Interactions',
        'icon': LucideIcons.alertOctagon,
      });
    }

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
                if (widget.drug.hasDiseaseInteraction)
                  _buildDiseaseInteractionsTab(theme, isRTL, colorScheme),
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
                        'Updated ${DateFormatter.formatDate(widget.drug.lastPriceUpdate)}',
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
              if (widget.drug.usage.isNotEmpty)
                _buildCard(
                  title: isRTL ? 'دواعي الاستعمال' : 'Indications (Usage)',
                  colorScheme: colorScheme,
                  child: Text(
                    widget.drug.usage,
                    style: TextStyle(
                      height: 1.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (widget.drug.usage.isNotEmpty) const SizedBox(height: 16),
              _buildCard(
                title: l10n.descriptionTitle,
                colorScheme: colorScheme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.drug.pharmacology != null &&
                        widget.drug.pharmacology!.isNotEmpty &&
                        widget.drug.pharmacology !=
                            widget.drug.description) ...[
                      Text(
                        widget.drug.pharmacology!,
                        style: TextStyle(
                          height: 1.5,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                    ],
                    Text(
                      widget.drug.description.isNotEmpty
                          ? widget.drug.description
                          : (widget.drug.usage.isEmpty
                              ? 'No extra description available.'
                              : 'See indications above.'),
                      style: TextStyle(
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
                      widget.drug.concentration.isNotEmpty
                          ? widget.drug.concentration
                          : 'Standard',
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
    return DosageTab(drug: widget.drug);
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
              hasDrugInteraction: drug.hasDrugInteraction,
              hasFoodInteraction: drug.hasFoodInteraction,
              hasDiseaseInteraction: drug.hasDiseaseInteraction,
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
              hasDrugInteraction: drug.hasDrugInteraction,
              hasFoodInteraction: drug.hasFoodInteraction,
              hasDiseaseInteraction: drug.hasDiseaseInteraction,
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
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        Provider.of<InteractionProvider>(
          context,
          listen: false,
        ).getDrugInteractions(widget.drug),
        Provider.of<InteractionProvider>(
          context,
          listen: false,
        ).getFoodInteractions(widget.drug),
      ]),
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

        final drugInteractions =
            snapshot.data?[0] as List<DrugInteraction>? ?? [];
        final foodInteractions = snapshot.data?[1] as List<String>? ?? [];

        if (drugInteractions.isEmpty && foodInteractions.isEmpty) {
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

        final sortedInteractions = List<DrugInteraction>.from(drugInteractions);
        sortedInteractions.sort((a, b) {
          const order = {
            InteractionSeverity.contraindicated: 0,
            InteractionSeverity.severe: 1,
            InteractionSeverity.major: 2,
            InteractionSeverity.moderate: 3,
            InteractionSeverity.minor: 4,
            InteractionSeverity.unknown: 5,
          };
          return (order[a.severityEnum] ?? 5).compareTo(
            order[b.severityEnum] ?? 5,
          );
        });

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (foodInteractions.isNotEmpty) ...[
              _buildCard(
                title: AppLocalizations.of(context)!.foodInteractionsTitle,
                colorScheme: colorScheme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      foodInteractions
                          .map(
                            (interaction) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    LucideIcons.apple,
                                    size: 16,
                                    color:
                                        Theme.of(
                                          context,
                                        ).appColors.warningForeground,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      interaction,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (sortedInteractions.isNotEmpty)
              ...sortedInteractions.map(
                (interaction) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InteractionCard(interaction: interaction),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDiseaseInteractionsTab(
    ThemeData theme,
    bool isRTL,
    ColorScheme colorScheme,
  ) {
    return FutureBuilder<List<DiseaseInteraction>>(
      future: Provider.of<InteractionProvider>(
        context,
        listen: false,
      ).getDiseaseInteractions(widget.drug),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading disease interactions',
              style: TextStyle(color: colorScheme.error),
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
                  Icon(
                    LucideIcons.shieldCheck,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isRTL ? 'لا توجد بيانات' : 'No data available',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: interactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final interaction = interactions[index];
            return _buildCard(
              title: interaction.diseaseName,
              colorScheme: colorScheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    interaction.interactionText,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      isRTL
                          ? 'المصدر: ${interaction.source}'
                          : 'Source: ${interaction.source}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1);
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
