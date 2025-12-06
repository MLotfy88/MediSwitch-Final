import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/design_tokens.dart';
import 'package:mediswitch/core/utils/animation_helpers.dart';
import 'package:mediswitch/presentation/screens/details/drug_details_screen.dart';
import 'package:mediswitch/presentation/screens/interaction_checker_screen.dart';
import 'package:mediswitch/presentation/screens/search/search_results_screen.dart';
import 'package:mediswitch/presentation/screens/weight_calculator_screen.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/widgets/app_header.dart';
import 'package:mediswitch/presentation/widgets/home/category_card.dart';
import 'package:mediswitch/presentation/widgets/home/dangerous_drug_card.dart';
import 'package:mediswitch/presentation/widgets/home/drug_card.dart';
import 'package:mediswitch/presentation/widgets/home_search_bar.dart';
import 'package:mediswitch/presentation/widgets/quick_tool_button.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/category_entity.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:provider/provider.dart';
import 'package:mediswitch/presentation/widgets/section_header.dart';
import 'package:mediswitch/presentation/utils/drug_entity_converter.dart';

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

                        // Quick Stats
                        Container(
                          padding: AppSpacing.paddingMD,
                          decoration: BoxDecoration(
                            color: Theme.of(context).appColors.successSoft,
                            borderRadius: AppRadius.circularLg,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                child: const Text(
                                  "+30 Drugs",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                              label: 'Interactions',
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
                              label: 'Dose Calc',
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
                        final categories = provider.categories;
                        if (categories.isEmpty) {
                          return const Center(child: Text("No categories"));
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return FadeSlideAnimation(
                              delay: StaggeredAnimationHelper.delayFor(index),
                              child: CategoryCard(
                                category: categories[index],
                                isRTL: isRTL,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Popular Drugs Section (was Dangerous Drugs)
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(
                      title: 'Popular Drugs',
                      subtitle: 'Most searched medicines',
                      icon: const Icon(LucideIcons.star), // Changed icon
                      iconBgColor: Theme.of(context).appColors.warningSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140,
                    child: Consumer<MedicineProvider>(
                      builder: (context, provider, child) {
                        final popularDrugs = provider.popularDrugs;
                        if (popularDrugs.isEmpty) {
                          return const Center(child: Text("No popular drugs"));
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: popularDrugs.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            return FadeSlideAnimation(
                              delay: StaggeredAnimationHelper.delayFor(index),
                              child: DangerousDrugCard(
                                drug: popularDrugs[index],
                                isRTL: isRTL,
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
                      title: 'Recently Added',
                      subtitle: 'New updates',
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
