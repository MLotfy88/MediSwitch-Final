import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../core/utils/currency_helper.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../presentation/bloc/interaction_provider.dart';
import '../../presentation/bloc/medicine_provider.dart';
import '../../presentation/theme/app_colors.dart';
import '../../presentation/widgets/cards/modern_drug_card.dart';
import '../../presentation/widgets/interaction_card.dart';
import '../../presentation/widgets/modern_badge.dart';

class DrugDetailsScreen extends StatefulWidget {
  final DrugEntity drug;
  static const routeName = '/drug-details';

  const DrugDetailsScreen({super.key, required this.drug});

  @override
  State<DrugDetailsScreen> createState() => _DrugDetailsScreenState();
}

class _DrugDetailsScreenState extends State<DrugDetailsScreen> {
  final FileLoggerService _logger = locator<FileLoggerService>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InteractionProvider>().getDrugInteractions(widget.drug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Tab definitions
    final tabs = [
      {'label': 'Info', 'icon': LucideIcons.info},
      {'label': 'Dosage', 'icon': LucideIcons.droplets},
      {'label': 'Alternatives', 'icon': LucideIcons.gitCompare},
      {'label': 'Interactions', 'icon': LucideIcons.alertTriangle},
      {'label': 'Price History', 'icon': LucideIcons.trendingDown},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DefaultTabController(
        length: tabs.length,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [_buildHeroHeader(context, isArabic, tabs)];
          },
          body: TabBarView(
            children: [
              _buildInfoTab(context, l10n),
              _buildDosageTab(context, l10n),
              _buildAlternativesTab(context, l10n),
              _buildInteractionsTab(context, l10n),
              _buildPriceHistoryTab(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    bool isArabic,
    List<Map<String, dynamic>> tabs,
  ) {
    // Price Calculation
    final double? currentPrice = double.tryParse(widget.drug.price);
    final double? oldPrice = double.tryParse(widget.drug.oldPrice ?? '');
    final bool hasDiscount =
        oldPrice != null && currentPrice != null && currentPrice < oldPrice;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.share2, color: Colors.white),
          onPressed: () {}, // TODO: Implement share
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
        const SizedBox(width: 8),
        Consumer<MedicineProvider>(
          builder: (context, provider, _) {
            final isFav = provider.isFavorite(widget.drug);
            return IconButton(
              icon: Icon(
                isFav ? LucideIcons.heart : LucideIcons.heart,
                color: isFav ? AppColors.danger : Colors.white,
              ),
              onPressed: () => provider.toggleFavorite(widget.drug),
              style: IconButton.styleFrom(
                backgroundColor:
                    isFav ? Colors.white : Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary, // "via-primary"
                Color(
                  0xFF005bb5,
                ), // Darker primary manual fallback or define in AppColors
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                60,
                16,
                16,
              ), // Adjust padding for AppBar height
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drug Icon & Name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          LucideIcons.pill,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.drug.tradeName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const ModernBadge(
                                  text: 'POPULAR',
                                  variant:
                                      BadgeVariant
                                          .popular, // Assuming logical mapping or hardcoded for now per docs
                                  size: BadgeSize.sm,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isArabic
                                  ? widget.drug.arabicName
                                  : widget
                                      .drug
                                      .arabicName, // Logic could be improved
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontFamily: 'Cairo', // Ensure font is loaded
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.drug.company,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Price Display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${widget.drug.price} ${CurrencyHelper.getCurrencySymbol(context)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30, // text-3xl
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (hasDiscount) ...[
                        Text(
                          widget.drug.oldPrice!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 18, // text-lg
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const ModernBadge(
                          text: 'Price Drop', // Localize later
                          variant: BadgeVariant.priceDown,
                          size:
                              BadgeSize
                                  .sm, // As "Variant priceDown" badge in docs
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: AppColors.background, // Match surface
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: TabBar(
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.mutedForeground,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            tabs:
                tabs
                    .map(
                      (t) => Tab(
                        child: Row(
                          children: [
                            Icon(t['icon'] as IconData, size: 16),
                            const SizedBox(width: 8),
                            Text(t['label'] as String),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ),
    );
  }

  // --- Tab Content Builders ---

  Widget _buildInfoTab(BuildContext context, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Description Card
        _buildInfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description', // Localize
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.drug.description.isNotEmpty
                    ? widget.drug.description
                    : 'No description available.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 16),

        // Details Card
        _buildInfoCard(
          child: Column(
            children: [
              _buildDetailRow(
                label: 'Active Ingredient',
                value: widget.drug.active,
                icon: LucideIcons.pill,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                label: 'Manufacturer',
                value: widget.drug.company,
                icon: LucideIcons.building2,
              ),
              const SizedBox(height: 16),
              // Mock Registration Number as it's not in Entity
              _buildDetailRow(
                label: 'Registration Number',
                value:
                    '#REG-${(widget.drug.id?.toString() ?? "00000").padLeft(5, '0').substring(0, 5)}',
                icon: LucideIcons.hash,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildDosageTab(BuildContext context, AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Strength Card (Combined Form & Strength logic)
        _buildInfoCard(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.droplets,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Strength',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  Text(
                    '${widget.drug.concentration} ${widget.drug.unit}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(),

        const SizedBox(height: 16),

        // Dosage Details
        _buildInfoCard(
          child: Column(
            children: [
              // Using Detail Row with custom icons
              _buildSimpleRow(
                icon: LucideIcons.clock,
                label: 'Usage',
                value: widget.drug.usage,
              ),
              const SizedBox(height: 12),
              _buildSimpleRow(
                icon: LucideIcons.info,
                label: 'Form',
                value: widget.drug.dosageForm,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),

        // Warning
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warningSoft,
            border: Border.all(color: AppColors.warning.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.alertTriangle,
                size: 20,
                color: AppColors.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Instruction',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please consult your doctor before taking this medication. Do not exceed the recommended dose.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.warning.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildAlternativesTab(BuildContext context, AppLocalizations l10n) {
    return FutureBuilder<List<DrugEntity>>(
      future: Provider.of<MedicineProvider>(
        context,
        listen: false,
      ).getAlternativeDrugs(widget.drug),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No alternatives found',
            LucideIcons.gitCompare,
          );
        }

        final alternatives = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: alternatives.length + 1, // +1 for Header Badge Count
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Found ${alternatives.length} alternatives',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            final drug = alternatives[index - 1];
            // Helper to create ModernDrugCard
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ModernDrugCard(
                drug: drug,
                isFavorite: false, // Ideally check provider
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DrugDetailsScreen(drug: drug),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInteractionsTab(BuildContext context, AppLocalizations l10n) {
    return FutureBuilder<List<DrugInteraction>>(
      future: Provider.of<InteractionProvider>(
        context,
        listen: false,
      ).getDrugInteractions(widget.drug),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Mocking interaction check logic roughly if empty, or just showing empty state
        // For real app, use snapshot
        // if (!snapshot.hasData || snapshot.data!.isEmpty) { ... }

        final interactions = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Warning Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Drug interactions can change how your medications work or increase your risk for serious side effects.',
                style: TextStyle(fontSize: 14, color: AppColors.danger),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 16),

            if (interactions.isEmpty)
              _buildEmptyState('No interactions found', LucideIcons.shieldCheck)
            else
              ...interactions.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InteractionCard(interaction: i),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPriceHistoryTab(BuildContext context, AppLocalizations l10n) {
    // Mock Price History
    final history = [
      {'date': '2023-11-01', 'price': widget.drug.price, 'change': 'Same'},
      // {'date': '2023-01-15', 'price': '45.0', 'change': 'up'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _buildInfoCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['date']!,
                style: const TextStyle(color: AppColors.mutedForeground),
              ),
              Row(
                children: [
                  Text(
                    '${item['price']} ${CurrencyHelper.getCurrencySymbol(context)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  // Badge could go here
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Helpers ---

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowCard,
      ),
      child: child,
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.mutedForeground),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.mutedForeground),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
