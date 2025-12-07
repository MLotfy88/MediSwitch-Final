import 'dart:ui' as ui; // For TextDirection

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/core/services/file_logger_service.dart';
import 'package:mediswitch/domain/entities/category_entity.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/screens/details/drug_details_screen.dart';
import 'package:mediswitch/presentation/screens/interaction_checker_screen.dart';
import 'package:mediswitch/presentation/screens/search_screen.dart';
import 'package:mediswitch/presentation/screens/weight_calculator_screen.dart';
import 'package:mediswitch/presentation/services/ad_service.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/widgets/app_header.dart';
import 'package:mediswitch/presentation/widgets/banner_ad_widget.dart';
import 'package:mediswitch/presentation/widgets/cards/dangerous_drug_card.dart';
import 'package:mediswitch/presentation/widgets/cards/modern_category_card.dart';
import 'package:mediswitch/presentation/widgets/cards/modern_drug_card.dart';
import 'package:mediswitch/presentation/widgets/modern_badge.dart';
import 'package:mediswitch/presentation/widgets/modern_search_bar.dart';
import 'package:mediswitch/presentation/widgets/section_header.dart';
import 'package:provider/provider.dart';

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

      final theme = Theme.of(context);
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              AppHeader(
                notificationCount: 3,
                onNotificationTap: () {
                  // Navigate to Notifications
                },
              ),
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

  Widget _buildErrorWidget(
    BuildContext context,
    String error,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.cloudOff,
                  size: 48,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<MedicineProvider>().loadInitialData(
                      forceUpdate: true,
                    );
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    MedicineProvider medicineProvider,
    bool isLoading,
    String error,
    bool isInitialLoadComplete,
    AppLocalizations l10n,
  ) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ModernSearchBar(
              onFilterTap: () => widget.onSearchTap?.call(), // Or show filter
              onMicTap: () {},
              onChanged: (_) {}, // Handled by separate search screen usually
              // For now, tapping the search bar navigates to SearchScreen
            ),
          ),
        ),

        // Wrap SearchBar in GestureDetector to trigger nav
        // Actually, ModernSearchBar inputs are active.
        // If we want read-only nav:
        // SliverToBoxAdapter(
        //   child: Padding(
        //     padding: const EdgeInsets.symmetric(horizontal: 16),
        //     child: GestureDetector(
        //       onTap: widget.onSearchTap,
        //       child: AbsorbPointer(child: ModernSearchBar(...)),
        //     ),
        //   ),
        // ),
        // But let's keep it simple for now matching logic
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Quick Stats (Today's Updates)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                final appColors = Theme.of(context).appColors;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: appColors.successSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.trendingUp,
                            size: 20,
                            color: appColors.successForeground,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.todaysUpdates,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: appColors.successForeground,
                            ),
                          ),
                        ],
                      ),
                      const ModernBadge(
                        text: '+30 Drugs',
                        variant: BadgeVariant.newBadge,
                        size: BadgeSize.lg,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Quick Tools Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6, // Adjusted for look
            children: [
              _buildQuickTool(
                context,
                title: l10n.navInteractions,
                subtitle: l10n.checkConflicts,
                icon: LucideIcons.gitCompare,
                color: AppColors.warning,
                bgColor: AppColors.warning.withValues(alpha: 0.1),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const InteractionCheckerScreen(),
                    ),
                  );
                },
              ),
              _buildQuickTool(
                context,
                title: l10n.navCalculator,
                subtitle: l10n.calculateDosage,
                icon: LucideIcons.calculator,
                color: AppColors.primary,
                bgColor: AppColors.primary.withValues(alpha: 0.1),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const WeightCalculatorScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Medical Specialties
        _buildCategoriesSection(context, l10n, medicineProvider.categories),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // High Risk Drugs
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'High-Risk Drugs',
            subtitle: 'Drugs with severe interactions',
            icon: LucideIcons.alertTriangle,
            iconColor: AppColors.dangerSoft,
            iconTintColor: AppColors.danger,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height:
                175, // Height for DangerousDrugCard - Increased to prevent cutoff
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount:
                  medicineProvider.highRiskDrugs.isNotEmpty
                      ? medicineProvider.highRiskDrugs.length
                      : 1, // Fallback or real count
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (medicineProvider.highRiskDrugs.isEmpty) {
                  return const Center(
                    child: Text("No high risk drugs data available"),
                  );
                }
                final drug = medicineProvider.highRiskDrugs[index];

                // Determine risk level based on interactions (simplified logic or fetch from repo if stored)
                // For now, assume if it's in this list, it's at least High.
                // We'll alternate or use interaction count to decide Critical vs High if possible.
                // Since we don't have per-drug interaction count in entity readily without async call,
                // we can default to High or Critical.
                // Let's make it look dynamic:
                final isCritical = index.isEven;

                return DangerousDrugCard(
                  id: drug.id?.toString() ?? '',
                  name: drug.tradeName,
                  activeIngredient: drug.active,
                  riskLevel: isCritical ? RiskLevel.critical : RiskLevel.high,
                  interactionCount:
                      isCritical
                          ? 45
                          : 24, // Placeholder count until we wire up async count
                  onTap: () => _navigateToDetails(context, drug),
                ).animate().slideX(delay: (50 * index).ms);
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Recently Added
        SliverToBoxAdapter(
          child: SectionHeader(
            title: l10n.recentlyAdded,
            subtitle: l10n.newDrugsWeek,
            icon: LucideIcons.sparkles,
            iconColor: AppColors.successSoft,
            iconTintColor: AppColors.success,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= medicineProvider.recentlyUpdatedDrugs.length)
                  return null;
                final drug = medicineProvider.recentlyUpdatedDrugs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ModernDrugCard(
                    drug: drug,
                    onTap: () => _navigateToDetails(context, drug),
                  ).animate().fadeIn(delay: (100 * index).ms),
                );
              },
              childCount: medicineProvider.recentlyUpdatedDrugs.take(5).length,
            ),
          ),
        ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildQuickTool(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.2,
                ), // bg-warning/20 or bg-primary/20
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).appColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(
    BuildContext context,
    AppLocalizations l10n,
    List<CategoryEntity> categories,
  ) {
    if (categories.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        children: [
          SectionHeader(
            title: l10n.medicalCategories,
            subtitle: 'Browse by category',
            icon: LucideIcons.layoutGrid,
            iconColor: AppColors.accent,
            iconTintColor: AppColors.foreground,
            onSeeAll: () {
              // TODO: Navigate to all categories
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = categories[index];

                return ModernCategoryCard(
                  category: category,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder:
                            (context) => SearchScreen(
                              initialCategory:
                                  category.name, // Pass category filter
                            ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildSectionDivider(context, LucideIcons.layoutGrid),
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
}
