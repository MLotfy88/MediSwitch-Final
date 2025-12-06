import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Modern Drug Details Screen with gradient hero header and tabs
/// Matches design-refresh/src/components/screens/DrugDetailsScreen.tsx
class NewDrugDetailsScreen extends StatefulWidget {
  final String? drugId;

  const NewDrugDetailsScreen({super.key, this.drugId});

  @override
  State<NewDrugDetailsScreen> createState() => _NewDrugDetailsScreenState();
}

class _NewDrugDetailsScreenState extends State<NewDrugDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;

  // Mock data - replace with actual data
  final mockDrug = {
    'tradeNameEn': 'Augmentin 1g',
    'tradeNameAr': 'اوجمنتين ١ جرام',
    'activeIngredient': 'Amoxicillin 875mg + Clavulanic Acid 125mg',
    'currentPrice': 185.00,
    'oldPrice': 195.00,
    'company': 'GlaxoSmithKline (GSK)',
    'registrationNumber': 'EGY-2024-00123',
    'description':
        'Augmentin is a combination antibiotic used to treat a wide variety of bacterial infections. It works by stopping the growth of bacteria.',
    've popular': true,
  };

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // final isRTL = Directionality.of(context) == TextDirection.rtl; // Unused

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Hero Header with Gradient
            SliverAppBar(
              expandedHeight: 240,
              pinned: false,
              stretch: true,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    // Share functionality
                  },
                  icon: const Icon(LucideIcons.share2, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _isFavorite = !_isFavorite);
                  },
                  icon: Icon(LucideIcons.heart, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        _isFavorite
                            ? colorScheme.error
                            : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Pill Icon
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  LucideIcons.pill,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mockDrug['tradeNameEn'] as String,
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      mockDrug['tradeNameAr'] as String,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                          ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Company
                          Text(
                            mockDrug['company'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Price
                          Row(
                            children: [
                              Text(
                                '${(mockDrug['currentPrice'] as double).toStringAsFixed(2)} EGP',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (mockDrug['oldPrice'] != null) ...[
                                Text(
                                  '${(mockDrug['oldPrice'] as double).toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiary.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.trendingDown,
                                        size: 12,
                                        color: colorScheme.tertiary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(((mockDrug['oldPrice'] as double) - (mockDrug['currentPrice'] as double)) / (mockDrug['oldPrice'] as double) * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: colorScheme.tertiary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
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
            ),

            // Sticky Tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 2,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(icon: Icon(LucideIcons.info, size: 16), text: 'Info'),
                    Tab(
                      icon: Icon(LucideIcons.droplets, size: 16),
                      text: 'Dosage',
                    ),
                    Tab(
                      icon: Icon(LucideIcons.gitCompare, size: 16),
                      text: 'Alternatives',
                    ),
                    Tab(
                      icon: Icon(LucideIcons.alertTriangle, size: 16),
                      text: 'Interactions',
                    ),
                    Tab(
                      icon: Icon(LucideIcons.trendingDown, size: 16),
                      text: 'Price',
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(context, colorScheme),
            _buildDosageTab(context, colorScheme),
            _buildAlternativesTab(context, colorScheme),
            _buildInteractionsTab(context, colorScheme),
            _buildPriceHistoryTab(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  mockDrug['description'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Details Card
          Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      context,
                      LucideIcons.flaskConical,
                      'Active Ingredient',
                      mockDrug['activeIngredient'] as String,
                      colorScheme,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      LucideIcons.building2,
                      'Manufacturer',
                      mockDrug['company'] as String,
                      colorScheme,
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      LucideIcons.hash,
                      'Registration Number',
                      mockDrug['registrationNumber'] as String,
                      colorScheme,
                    ),
                  ],
                ),
              )
              .animate(delay: 100.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDosageTab(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Placeholder - add actual dosage content
          _buildInfoCard(
            context,
            'Standard Dose',
            '1 Tablet every 12 hours',
            LucideIcons.pill,
            colorScheme,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            'Instructions',
            'Take at the start of a meal to reduce side effects',
            LucideIcons.info,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesTab(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Alternative medications with the same active ingredient',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        // Placeholder - add drug cards
        _buildInfoCard(
          context,
          'Hibiotic 1g',
          '145.00 EGP - Amoun Pharma',
          LucideIcons.pill,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildInteractionsTab(BuildContext context, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInteractionCard(
          context,
          'Warfarin',
          'major',
          'Increased risk of bleeding',
          colorScheme,
        ),
        const SizedBox(height: 12),
        _buildInteractionCard(
          context,
          'Methotrexate',
          'major',
          'Increased methotrexate toxicity',
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildPriceHistoryTab(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            context,
            'Current Price',
            '185.00 EGP',
            LucideIcons.trendingDown,
            colorScheme,
          ),
          const SizedBox(height: 16),
          Text(
            'Price history chart coming soon...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionCard(
    BuildContext context,
    String drugName,
    String severity,
    String description,
    ColorScheme colorScheme,
  ) {
    final severityColor =
        severity == 'major'
            ? colorScheme.error
            : severity == 'moderate'
            ? Colors.orange
            : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  drugName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// Sticky Tab Bar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
