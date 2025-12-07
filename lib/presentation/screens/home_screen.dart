import 'dart:ui' as ui; // For TextDirection

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

// import '../services/ad_service.dart'; // Make sure this path is correct or removed if not used directly
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/drug_entity.dart';
import '../../presentation/theme/app_colors.dart';
import '../bloc/medicine_provider.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/category_card.dart';
import '../widgets/drug_card.dart';
import '../widgets/high_risk_drugs_card.dart';
import '../widgets/home_header.dart';
import '../widgets/horizontal_list_section.dart';
import '../widgets/price_alerts_card.dart';
import '../widgets/quick_tool_button.dart';
import '../widgets/search_bar_button.dart';
import '../widgets/skeleton_loader.dart';
import 'drug_details_screen.dart';
import 'interaction_checker_screen.dart';
import 'search_screen.dart';
import 'weight_calculator_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onSearchTap;

  const HomeScreen({super.key, this.onSearchTap});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdService _adService = locator<AdService>();
  final FileLoggerService _logger = locator<FileLoggerService>();

  @override
  void initState() {
    super.initState();
    _logger.i("HomeScreen: +++++ initState +++++");
  }

  @override
  void dispose() {
    _logger.i("HomeScreen: ----- dispose -----");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("HomeScreen: >>>>> build ENTRY <<<<<");
    try {
      final l10n = AppLocalizations.of(context)!;
      final medicineProvider = context.watch<MedicineProvider>();
      final isLoading = medicineProvider.isLoading;
      final error = medicineProvider.error;
      final isInitialLoadComplete = medicineProvider.isInitialLoadComplete;
      final recentlyUpdatedCount = medicineProvider.recentlyUpdatedDrugs.length;
      final popularCount = medicineProvider.popularDrugs.length;

      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const HomeHeader(notificationCount: 3),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    return context.read<MedicineProvider>().loadInitialData(
                      forceUpdate: true,
                    );
                  },
                  child:
                      isLoading && !isInitialLoadComplete
                          ? _buildLoadingIndicator()
                          : error.isNotEmpty
                          ? _buildErrorWidget(context, error, l10n)
                          : (isInitialLoadComplete ||
                              recentlyUpdatedCount > 0 ||
                              popularCount > 0)
                          ? _buildContent(
                            context,
                            medicineProvider,
                            isLoading,
                            error,
                            isInitialLoadComplete,
                            l10n,
                          )
                          : _buildLoadingIndicator(),
                ),
              ),
              const BannerAdWidget(placement: BannerAdPlacement.homeBottom),
            ],
          ),
        ),
      );
    } catch (e, s) {
      _logger.e("HomeScreen: >>>>> CRITICAL ERROR DURING BUILD <<<<<", e, s);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error building HomeScreen:\n$e\n\n$s',
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textDirection: ui.TextDirection.ltr,
            ),
          ),
        ),
      );
    } finally {
      _logger.i("HomeScreen: >>>>> build EXIT <<<<<");
    }
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent(
    BuildContext context,
    MedicineProvider medicineProvider,
    bool isLoading,
    String error,
    bool isInitialLoadComplete,
    AppLocalizations l10n,
  ) {
    // Filter High Risk Drugs based on common keywords if not already handled provided
    // This is a naive filter but better than random.
    // List of known high risk / narrow therapeutic index drugs
    final highRiskKeywords = [
      'warfarin',
      'digoxin',
      'insulin',
      'lithium',
      'theophylline',
      'phenytoin',
      'carbamazepine',
      'methotrexate',
    ];
    final highRiskDrugs =
        medicineProvider.filteredMedicines
            .where((drug) {
              final name =
                  drug.tradeName.toLowerCase() +
                  " " +
                  drug.active.toLowerCase();
              return highRiskKeywords.any((k) => name.contains(k));
            })
            .take(10)
            .toList();

    // If specific filter found nothing, fallback to simple logic or empty (don't show random)
    // Or prioritize drugs with known interactions if available in entity

    final displayHighRiskDrugs =
        highRiskDrugs.isNotEmpty
            ? highRiskDrugs
            : medicineProvider.filteredMedicines
                .take(0)
                .toList(); // Show nothing if no match, better than random

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Search Bar
        SliverToBoxAdapter(child: SearchBarButton(onTap: widget.onSearchTap)),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Today's Updates Banner (Matches Reference)
        SliverToBoxAdapter(
          child:
              !isInitialLoadComplete
                  ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SkeletonCard(height: 80),
                  )
                  : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Builder(
                      builder: (context) {
                        // Recalculate or just use recent count as proxy like design
                        final recentCount =
                            medicineProvider.recentlyUpdatedDrugs.length;
                        final displayText =
                            recentCount > 0
                                ? '+$recentCount Drugs'
                                : 'No updates';

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.trendingUp,
                                    size: 20,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Today's Updates", // Localize me if needed
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  displayText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Quick Tools Buttons (Interactions & Calculator)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                QuickToolButton(
                  icon: LucideIcons.gitCompare,
                  label:
                      l10n.navInteractions, // Use localized label "Interactions" or similar
                  subtitle: 'Check conflicts', // Localize
                  color:
                      AppColors.warning, // Matches Reference (Warning/Orange)
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InteractionCheckerScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                QuickToolButton(
                  icon: LucideIcons.calculator,
                  label: l10n.navCalculator, // Use localized label "Dose Calc"
                  subtitle: 'Calculate dosage', // Localize
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.primary, // Matches Reference (Primary/Blue)
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WeightCalculatorScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Price Alerts
        if (!isInitialLoadComplete)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SkeletonCard(height: 180),
            ),
          )
        else if (medicineProvider.recentlyUpdatedDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: PriceAlertsCard(
              topChangedDrugs: _getTopChangedDrugs(
                medicineProvider.recentlyUpdatedDrugs,
                3,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // High Risk Drugs - Now using filtered list
        if (!isInitialLoadComplete)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SkeletonCard(height: 180),
            ),
          )
        else if (displayHighRiskDrugs
            .isNotEmpty) // Only show if we found actual high risk drugs
          SliverToBoxAdapter(
            child: HighRiskDrugsCard(
              allDrugs: displayHighRiskDrugs,
              onDrugTap: (drug) => _navigateToDetails(context, drug),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Medical Categories - Changed to Horizontal List
        if (medicineProvider.categories.isNotEmpty)
          _buildCategoriesSection(context, l10n, medicineProvider.categories),

        // Recently Added (Matches Reference - Vertical List)
        if (!isInitialLoadComplete)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: SkeletonList(height: 270),
            ),
          )
        else if (medicineProvider.recentlyUpdatedDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header matching reference
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.successSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.sparkles,
                          size: 16,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recently Added', // Matches reference title
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'New drugs this week',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Vertical List of DrugCards
                  ...medicineProvider.recentlyUpdatedDrugs
                      .take(3)
                      .map(
                        (drug) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DrugCard(
                            drug: drug,
                            type: DrugCardType.detailed,
                            onTap: () => _navigateToDetails(context, drug),
                          ).animate().fadeIn(
                            delay:
                                (medicineProvider.recentlyUpdatedDrugs.indexOf(
                                          drug,
                                        ) *
                                        100)
                                    .ms,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),

        // Popular Drugs
        if (!medicineProvider.isInitialLoadComplete)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: SkeletonList(height: 200),
            ),
          )
        else if (medicineProvider.popularDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildHorizontalDrugList(
              context,
              title: l10n.mostSearchedDrugs,
              icon: LucideIcons.trendingUp,
              drugs: medicineProvider.popularDrugs,
              isPopular: true,
              onViewAll: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SearchScreen(initialQuery: ''),
                  ),
                );
              },
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  // Helper to count price increases/decreases
  int _countPriceChanges(List<DrugEntity> drugs, bool isIncrease) {
    int count = 0;
    for (final drug in drugs) {
      final oldPrice = double.tryParse(drug.oldPrice ?? '0') ?? 0;
      final currentPrice = double.tryParse(drug.price) ?? 0;
      if (oldPrice > 0 && currentPrice > 0 && oldPrice != currentPrice) {
        if (isIncrease && currentPrice > oldPrice)
          count++;
        else if (!isIncrease && currentPrice < oldPrice)
          count++;
      }
    }
    return count;
  }

  // Helper to get top changed drugs
  List<DrugEntity> _getTopChangedDrugs(List<DrugEntity> drugs, int count) {
    final changedDrugs =
        drugs.where((drug) {
          final oldPrice = double.tryParse(drug.oldPrice ?? '0') ?? 0;
          final currentPrice = double.tryParse(drug.price) ?? 0;
          return oldPrice > 0 && currentPrice > 0 && oldPrice != currentPrice;
        }).toList();

    changedDrugs.sort((a, b) {
      final oldPriceA = double.tryParse(a.oldPrice ?? '0') ?? 0;
      final currentPriceA = double.tryParse(a.price) ?? 0;
      final percentageA = ((currentPriceA - oldPriceA) / oldPriceA * 100).abs();

      final oldPriceB = double.tryParse(b.oldPrice ?? '0') ?? 0;
      final currentPriceB = double.tryParse(b.price) ?? 0;
      final percentageB = ((currentPriceB - oldPriceB) / oldPriceB * 100).abs();

      return percentageB.compareTo(percentageA);
    });

    return changedDrugs.take(count).toList();
  }

  Widget _buildHorizontalDrugList(
    BuildContext context, {
    required String title,
    required List<DrugEntity> drugs,
    VoidCallback? onViewAll,
    double listHeight = 270,
    bool isPopular = false,
    IconData? icon,
  }) {
    return SizedBox(
      height: listHeight,
      child: HorizontalListSection(
        title: title,
        icon: icon,
        onViewAll: onViewAll,
        listHeight: listHeight,
        listPadding: const EdgeInsets.symmetric(horizontal: 16),
        children:
            drugs
                .map(
                  (drug) => DrugCard(
                    drug: drug,
                    type: DrugCardType.thumbnail,
                    isPopular: isPopular,
                    onTap: () => _navigateToDetails(context, drug),
                  ).animate().fadeIn(delay: (drugs.indexOf(drug) * 80).ms),
                )
                .toList(),
      ),
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    AppLocalizations l10n,
    List<CategoryEntity> categories,
  ) {
    // Mapping dictionary: Full category name → display data
    // This maps real database category names to short display names with icons and colors
    final Map<String, Map<String, dynamic>> categoryMapping = {
      // Cardiology / Heart
      'cardiology': {
        'short': 'Cardiac',
        'shortAr': 'قلب',
        'icon': LucideIcons.heart,
        'color': 'red',
      },
      'cardiovascular': {
        'short': 'Cardiac',
        'shortAr': 'قلب',
        'icon': LucideIcons.heart,
        'color': 'red',
      },
      'heart': {
        'short': 'Cardiac',
        'shortAr': 'قلب',
        'icon': LucideIcons.heart,
        'color': 'red',
      },
      // Neurology
      'neurology': {
        'short': 'Neuro',
        'shortAr': 'أعصاب',
        'icon': LucideIcons.brain,
        'color': 'purple',
      },
      'neurological': {
        'short': 'Neuro',
        'shortAr': 'أعصاب',
        'icon': LucideIcons.brain,
        'color': 'purple',
      },
      'cns': {
        'short': 'Neuro',
        'shortAr': 'أعصاب',
        'icon': LucideIcons.brain,
        'color': 'purple',
      },
      // Dental
      'dental': {
        'short': 'Dental',
        'shortAr': 'أسنان',
        'icon': LucideIcons.smile,
        'color': 'teal',
      },
      'dentistry': {
        'short': 'Dental',
        'shortAr': 'أسنان',
        'icon': LucideIcons.smile,
        'color': 'teal',
      },
      // Pediatrics
      'pediatric': {
        'short': 'Pediatric',
        'shortAr': 'أطفال',
        'icon': LucideIcons.baby,
        'color': 'green',
      },
      'pediatrics': {
        'short': 'Pediatric',
        'shortAr': 'أطفال',
        'icon': LucideIcons.baby,
        'color': 'green',
      },
      'children': {
        'short': 'Pediatric',
        'shortAr': 'أطفال',
        'icon': LucideIcons.baby,
        'color': 'green',
      },
      // Ophthalmology
      'ophthalmology': {
        'short': 'Eyes',
        'shortAr': 'عيون',
        'icon': LucideIcons.eye,
        'color': 'blue',
      },
      'ophthalmic': {
        'short': 'Eyes',
        'shortAr': 'عيون',
        'icon': LucideIcons.eye,
        'color': 'blue',
      },
      'eye': {
        'short': 'Eyes',
        'shortAr': 'عيون',
        'icon': LucideIcons.eye,
        'color': 'blue',
      },
      // Orthopedics
      'orthopedic': {
        'short': 'Ortho',
        'shortAr': 'عظام',
        'icon': LucideIcons.bone,
        'color': 'orange',
      },
      'orthopedics': {
        'short': 'Ortho',
        'shortAr': 'عظام',
        'icon': LucideIcons.bone,
        'color': 'orange',
      },
      'musculoskeletal': {
        'short': 'Ortho',
        'shortAr': 'عظام',
        'icon': LucideIcons.bone,
        'color': 'orange',
      },
      // Dermatology
      'dermatology': {
        'short': 'Derma',
        'shortAr': 'جلدية',
        'icon': LucideIcons.hand,
        'color': 'purple',
      },
      'skin': {
        'short': 'Derma',
        'shortAr': 'جلدية',
        'icon': LucideIcons.hand,
        'color': 'purple',
      },
      // Gastroenterology
      'gastroenterology': {
        'short': 'GI',
        'shortAr': 'هضمي',
        'icon': LucideIcons.pill,
        'color': 'orange',
      },
      'gastrointestinal': {
        'short': 'GI',
        'shortAr': 'هضمي',
        'icon': LucideIcons.pill,
        'color': 'orange',
      },
      'digestive': {
        'short': 'GI',
        'shortAr': 'هضمي',
        'icon': LucideIcons.pill,
        'color': 'orange',
      },
      // Respiratory
      'respiratory': {
        'short': 'Resp',
        'shortAr': 'تنفسي',
        'icon': LucideIcons.wind,
        'color': 'blue',
      },
      'pulmonology': {
        'short': 'Resp',
        'shortAr': 'تنفسي',
        'icon': LucideIcons.wind,
        'color': 'blue',
      },
      // Endocrinology
      'endocrinology': {
        'short': 'Endo',
        'shortAr': 'غدد',
        'icon': LucideIcons.activity,
        'color': 'teal',
      },
      'diabetes': {
        'short': 'Endo',
        'shortAr': 'غدد',
        'icon': LucideIcons.activity,
        'color': 'teal',
      },
      // Antibiotics
      'antibiotic': {
        'short': 'Antibio',
        'shortAr': 'مضاد',
        'icon': LucideIcons.shield,
        'color': 'red',
      },
      'antibiotics': {
        'short': 'Antibio',
        'shortAr': 'مضاد',
        'icon': LucideIcons.shield,
        'color': 'red',
      },
      'anti-infective': {
        'short': 'Antibio',
        'shortAr': 'مضاد',
        'icon': LucideIcons.shield,
        'color': 'red',
      },
      // Pain / Analgesics
      'analgesic': {
        'short': 'Pain',
        'shortAr': 'مسكن',
        'icon': LucideIcons.thermometer,
        'color': 'orange',
      },
      'pain': {
        'short': 'Pain',
        'shortAr': 'مسكن',
        'icon': LucideIcons.thermometer,
        'color': 'orange',
      },
      // Default fallback
    };

    // Get drug counts per category from filteredMedicines
    final allDrugs = context.read<MedicineProvider>().filteredMedicines;
    Map<String, int> categoryCounts = {};
    for (var cat in categories) {
      final count =
          allDrugs
              .where((d) => d.category?.toLowerCase() == cat.name.toLowerCase())
              .length;
      categoryCounts[cat.name] = count;
    }

    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    // Build display list from real categories
    final displayCategories =
        categories.take(8).map((cat) {
          final lowerName = cat.name.toLowerCase();
          final mapping =
              categoryMapping[lowerName] ??
              // Fallback for unmapped categories
              {
                'short':
                    cat.name.length > 8
                        ? '${cat.name.substring(0, 7)}.'
                        : cat.name,
                'shortAr': cat.nameAr,
                'icon': LucideIcons.pill,
                'color': 'blue',
              };

          return {
            'originalName': cat.name,
            'displayName': isArabic ? mapping['shortAr'] : mapping['short'],
            'icon': mapping['icon'] as IconData,
            'color': mapping['color'] as String,
            'count': categoryCounts[cat.name] ?? cat.drugCount,
          };
        }).toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: HorizontalListSection(
              title: l10n.medicalCategories,
              icon: LucideIcons.layoutGrid,
              listHeight: 140,
              listPadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 8,
              ),
              children:
                  displayCategories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CategoryCard(
                        name: cat['displayName'] as String,
                        iconData: cat['icon'] as IconData,
                        drugCount: cat['count'] as int,
                        colorKey: cat['color'] as String,
                        onTap: () {
                          _adService.incrementUsageCounterAndShowAdIfNeeded();
                          context.read<MedicineProvider>().setCategory(
                            cat['originalName'] as String,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder:
                                  (_) => SearchScreen(
                                    initialCategory:
                                        cat['originalName'] as String,
                                  ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          _buildSectionDivider(context, LucideIcons.pill),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 8,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          Icon(icon, size: 12, color: colorScheme.outlineVariant),
          Expanded(
            child: Divider(
              height: 1,
              thickness: 1,
              indent: 8,
              endIndent: 16,
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetails(BuildContext context, DrugEntity drug) {
    _logger.i("HomeScreen: Navigating to details for drug: ${drug.tradeName}");
    _adService.incrementUsageCounterAndShowAdIfNeeded();
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => DrugDetailsScreen(drug: drug),
      ),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    String error,
    AppLocalizations l10n,
  ) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: Theme.of(context).colorScheme.error,
            size: 64.0,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.errorOccurred,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.refreshCw),
            label: Text(l10n.retry),
            onPressed: () {
              context.read<MedicineProvider>().loadInitialData(
                forceUpdate: true,
              );
            },
          ),
        ],
      ),
    );
  }
}
