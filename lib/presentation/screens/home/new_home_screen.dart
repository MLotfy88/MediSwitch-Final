import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/design_tokens.dart';
import 'package:mediswitch/core/utils/animation_helpers.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/screens/details/drug_details_screen.dart';
import 'package:mediswitch/presentation/screens/interaction_checker_screen.dart';
import 'package:mediswitch/presentation/screens/search/search_results_screen.dart';
import 'package:mediswitch/presentation/screens/weight_calculator_screen.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/utils/category_mapper.dart';
import 'package:mediswitch/presentation/utils/drug_entity_converter.dart';
import 'package:mediswitch/presentation/widgets/app_header.dart';
import 'package:mediswitch/presentation/widgets/home/category_card.dart';
import 'package:mediswitch/presentation/widgets/home/drug_card.dart';
import 'package:mediswitch/presentation/widgets/home_search_bar.dart';
import 'package:mediswitch/presentation/widgets/quick_tool_button.dart';
import 'package:mediswitch/presentation/widgets/section_header.dart';
import 'package:provider/provider.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refresh data when screen loads
      Provider.of<MedicineProvider>(context, listen: false).loadInitialData();
    });
  }

  void _toggleFavorite(String id) {
    // TODO: Implement favorite toggling through provider
  }

  @override
  Widget build(BuildContext context) {
    // Check RTL from context or locale
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
              child: Column(
                children: [
                  // Search Section
                  Padding(
                    padding: AppSpacing.paddingLG,
                    child: Column(
                      children: [
                        HomeSearchBar(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SearchResultsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Quick Stats - Today's Updates
                        Consumer<MedicineProvider>(
                          builder: (context, provider, child) {
                            final recentCount =
                                provider.recentlyUpdatedDrugs.length;
                            final displayText =
                                recentCount > 0
                                    ? '+$recentCount Drugs'
                                    : 'No updates';

                            return Container(
                              padding: AppSpacing.paddingMD,
                              decoration: BoxDecoration(
                                color: Theme.of(context).appColors.successSoft,
                                borderRadius: AppRadius.circularLg,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.trendingUp,
                                        size: 20,
                                        color:
                                            Theme.of(
                                              context,
                                            ).appColors.successForeground,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        "Today's Updates",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              Theme.of(
                                                context,
                                              ).appColors.successForeground,
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
                                      color:
                                          Theme.of(
                                            context,
                                          ).appColors.successForeground,
                                      borderRadius: AppRadius.circularSm,
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
                      ],
                    ),
                  ),

                  // Quick Tools (NEW)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            QuickToolButton(
                              icon: LucideIcons.gitCompare,
                              label: 'Drug\nInteractions',
                              subtitle: 'Check conflicts',
                              color:
                                  Theme.of(context).appColors.warningForeground,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => const InteractionCheckerScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            QuickToolButton(
                              icon: LucideIcons.calculator,
                              label: 'Dosage\nCalculator',
                              subtitle: 'Calculate dosage',
                              color: Theme.of(context).colorScheme.primary,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => const WeightCalculatorScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Spacing before Categories
                  const SizedBox(height: 24),

                  // Categories Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(
                      title: 'Medical Specialties',
                      subtitle: 'Browse by category',
                      icon: const Icon(LucideIcons.pill),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: Consumer<MedicineProvider>(
                      builder: (context, provider, child) {
                        final realCategories = provider.categories;
                        if (realCategories.isEmpty) {
                          return const Center(child: Text("No categories"));
                        }

                        // تطبيق mapping للتطابق 100% مع التصميم المرجعي
                        final mappedCategories = CategoryMapper.mapCategories(
                          realCategories,
                        );

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: mappedCategories.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return FadeSlideAnimation(
                              delay: StaggeredAnimationHelper.delayFor(index),
                              child: CategoryCard(
                                category: mappedCategories[index],
                                isRTL: isRTL,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // High-Risk Drugs Section
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(
                      title: 'High-Risk Drugs',
                      subtitle: 'Drugs with severe interactions',
                      icon: const Icon(LucideIcons.alertTriangle),
                      iconBgColor: Theme.of(context).appColors.dangerSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: Consumer<MedicineProvider>(
                      builder: (context, provider, child) {
                        final popularDrugs = provider.popularDrugs;
                        if (popularDrugs.isEmpty) {
                          return const Center(
                            child: Text("No high-risk drugs"),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: popularDrugs.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final drug = popularDrugs[index];
                            final isFav = provider.isFavorite(drug);
                            return FadeSlideAnimation(
                              delay: StaggeredAnimationHelper.delayFor(index),
                              child: SizedBox(
                                width: 280,
                                child: DrugCard(
                                  drug: drugEntityToUIModel(
                                    drug,
                                    isFavorite: isFav,
                                  ),
                                  onFavoriteToggle:
                                      (String drugId) =>
                                          provider.toggleFavorite(drug),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder:
                                            (context) =>
                                                DrugDetailsScreen(drug: drug),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Recently Added Section
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(
                      title: 'Recently Updated',
                      subtitle: 'New drugs this week',
                      icon: const Icon(LucideIcons.sparkles),
                      iconBgColor: Theme.of(context).appColors.successSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<MedicineProvider>(
                    builder: (context, provider, child) {
                      final recentDrugs = provider.recentlyUpdatedDrugs;
                      if (recentDrugs.isEmpty) {
                        return const Center(child: Text("No recent updates"));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: recentDrugs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final drug = recentDrugs[index];
                          final isFav = provider.isFavorite(drug);
                          return FadeSlideAnimation(
                            delay: StaggeredAnimationHelper.delayFor(
                              index,
                              baseDelay: const Duration(milliseconds: 30),
                            ),
                            child: DrugCard(
                              drug: drugEntityToUIModel(
                                drug,
                                isFavorite: isFav,
                              ),
                              onFavoriteToggle:
                                  (String drugId) =>
                                      provider.toggleFavorite(drug),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder:
                                        (context) =>
                                            DrugDetailsScreen(drug: drug),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
