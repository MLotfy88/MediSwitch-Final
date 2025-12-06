import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'dart:ui' as ui; // For TextDirection

import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/medicine_provider.dart';
import 'search_screen.dart';
import 'drug_details_screen.dart';
import '../widgets/drug_card.dart';
import '../widgets/section_header.dart';
import '../widgets/home_header.dart';
import '../widgets/horizontal_list_section.dart';
import '../widgets/category_card.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/search_bar_button.dart';
import '../widgets/quick_stats_banner.dart';
import '../widgets/price_alerts_card.dart';
import '../widgets/high_risk_drugs_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/empty_state_widget.dart'; // Kept if needed, though previously unused warning
// import '../services/ad_service.dart'; // Make sure this path is correct or removed if not used directly
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_spacing.dart';
import '../services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
              const BannerAdWidget(),
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
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: const SearchBarButton()),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Quick Stats Banner
        SliverToBoxAdapter(
          child:
              !isInitialLoadComplete
                  ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SkeletonCard(height: 100),
                  )
                  : Builder(
                    builder: (context) {
                      final today = DateTime.now();
                      final todayStr = DateFormat('yyyy-MM-dd').format(today);
                      final todayDrugs =
                          medicineProvider.recentlyUpdatedDrugs.where((d) {
                            if (d.lastPriceUpdate.isEmpty) return false;
                            if (d.lastPriceUpdate.startsWith(todayStr))
                              return true;
                            try {
                              final dDate = DateTime.parse(d.lastPriceUpdate);
                              return dDate.year == today.year &&
                                  dDate.month == today.month &&
                                  dDate.day == today.day;
                            } catch (_) {
                              return false;
                            }
                          }).toList();

                      return QuickStatsBanner(
                        totalDrugs: medicineProvider.filteredMedicines.length,
                        todayUpdates: todayDrugs.length,
                        priceIncreases: _countPriceChanges(todayDrugs, true),
                        priceDecreases: _countPriceChanges(todayDrugs, false),
                      );
                    },
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

        // Recently Updated
        if (!isInitialLoadComplete)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: SkeletonList(height: 270),
            ),
          )
        else if (medicineProvider.recentlyUpdatedDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildHorizontalDrugList(
                  context,
                  title: l10n.recentlyUpdatedDrugs,
                  icon: LucideIcons.history,
                  // Limit display to top 10 recent drugs
                  drugs:
                      medicineProvider.recentlyUpdatedDrugs.take(10).toList(),
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SearchScreen(initialQuery: ''),
                      ),
                    );
                  },
                ),
                _buildSectionDivider(context, LucideIcons.activity),
              ],
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
    if (categories.isEmpty) return const SizedBox.shrink();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Use HorizontalListSection with strip of cards (CategoryCard)
          // Adjust CategoryCard width in HorizontalListSection or wrap in SizedBox
          SizedBox(
            height: 130, // Adjust height for category cards
            child: HorizontalListSection(
              title: l10n.medicalCategories,
              icon: LucideIcons.layoutGrid,
              listHeight: 130,
              listPadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 8,
              ),
              children:
                  categories.map((categoryEntity) {
                    final englishCategoryName =
                        categoryEntity.id; // Use id as category name
                    final locale = Localizations.localeOf(context);
                    final isArabic = locale.languageCode == 'ar';
                    final normalizedKey = englishCategoryName
                        .replaceAllMapped(
                          RegExp(r'([A-Z])'),
                          (match) => '_${match.group(1)}',
                        )
                        .replaceAll(' ', '_')
                        .toLowerCase()
                        .replaceAll(RegExp(r'^_+'), '');

                    final String displayName =
                        isArabic
                            ? kCategoryTranslation[englishCategoryName] ??
                                englishCategoryName
                            : englishCategoryName;

                    final iconData =
                        kCategoryIcons[normalizedKey] ??
                        kCategoryIcons['default']!;

                    return Container(
                      width: 140, // Fixed width for consistency
                      margin: const EdgeInsets.only(bottom: 8),
                      child: CategoryCard(
                        key: ValueKey(englishCategoryName),
                        name: displayName,
                        iconData: iconData,
                        onTap: () {
                          _adService.incrementUsageCounterAndShowAdIfNeeded();
                          context.read<MedicineProvider>().setCategory(
                            englishCategoryName,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder:
                                  (_) => SearchScreen(
                                    initialCategory: englishCategoryName,
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
