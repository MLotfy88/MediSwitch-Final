import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/design_tokens.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/presentation/bloc/interaction_provider.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/utils/drug_entity_converter.dart';
import 'package:mediswitch/presentation/widgets/home/drug_card.dart';
import 'package:mediswitch/presentation/widgets/interaction_card.dart';
import 'package:provider/provider.dart';

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
    } catch (e) {
      return dateStr; // Return original if parsing fails
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
        'label': 'Similarities',
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
                          color: colorScheme.onPrimary.withOpacity(0.8),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.drug.company,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                  // Last Updated Date
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.refreshCw,
                        size: 14,
                        color: colorScheme.onPrimary.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Updated ${_formatDate(widget.drug.lastPriceUpdate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimary.withOpacity(0.6),
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

      case 'similarities':
        // المثائل - نفس المادة الفعالة
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: similars.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final drug = similars[index];
                final isFav = Provider.of<MedicineProvider>(
                  context,
                  listen: false,
                ).isFavorite(drug);

                return DrugCard(
                  drug: drugEntityToUIModel(drug, isFavorite: isFav),
                  onFavoriteToggle:
                      (_) => Provider.of<MedicineProvider>(
                        context,
                        listen: false,
                      ).toggleFavorite(drug),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DrugDetailsScreen(drug: drug),
                      ),
                    );
                  },
                );
              },
            );
          },
        ).animate().fadeIn();

      case 'alternatives':
        // البدائل - أدوية بنفس الـ description
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alternatives.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final drug = alternatives[index];
                final isFav = Provider.of<MedicineProvider>(
                  context,
                  listen: false,
                ).isFavorite(drug);

                return DrugCard(
                  drug: drugEntityToUIModel(drug, isFavorite: isFav),
                  onFavoriteToggle:
                      (_) => Provider.of<MedicineProvider>(
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
        ).animate().fadeIn();

      case 'interactions':
        // Drug Interactions
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
                        isRTL
                            ? 'لا توجد تفاعلات معروفة'
                            : 'No Known Interactions',
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

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: interactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return InteractionCard(interaction: interactions[index]);
              },
            );
          },
        ).animate().fadeIn();

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
