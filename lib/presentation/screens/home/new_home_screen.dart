import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_header.dart';
import '../../widgets/home_search_bar.dart';
import '../../widgets/home/category_card.dart';
import '../../widgets/home/dangerous_drug_card.dart';
import '../../widgets/home/drug_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/horizontal_list_section.dart';
import '../details/drug_details_screen.dart';
import '../search/search_results_screen.dart';
import '../settings/new_settings_screen.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({Key? key}) : super(key: key);

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final Set<String> _favorites = {'2'};

  // Mock Data
  final List<CategoryModel> categories = [
    CategoryModel(
      id: '1',
      name: 'Cardiac',
      nameAr: 'قلب',
      icon: LucideIcons.heart,
      drugCount: 245,
      color: 'red',
    ),
    CategoryModel(
      id: '2',
      name: 'Neuro',
      nameAr: 'أعصاب',
      icon: LucideIcons.brain,
      drugCount: 189,
      color: 'purple',
    ),
    CategoryModel(
      id: '3',
      name: 'Dental',
      nameAr: 'أسنان',
      icon: LucideIcons.smile,
      drugCount: 78,
      color: 'teal',
    ),
    CategoryModel(
      id: '4',
      name: 'Pediatric',
      nameAr: 'أطفال',
      icon: LucideIcons.baby,
      drugCount: 156,
      color: 'green',
    ),
    CategoryModel(
      id: '5',
      name: 'Ophthalmic',
      nameAr: 'عيون',
      icon: LucideIcons.eye,
      drugCount: 92,
      color: 'blue',
    ),
    CategoryModel(
      id: '6',
      name: 'Orthopedic',
      nameAr: 'عظام',
      icon: LucideIcons.bone,
      drugCount: 134,
      color: 'orange',
    ),
  ];

  final List<DangerousDrugModel> dangerousDrugs = [
    DangerousDrugModel(
      id: '1',
      name: 'Warfarin',
      activeIngredient: 'Warfarin Sodium',
      riskLevel: 'critical',
      interactionCount: 47,
    ),
    DangerousDrugModel(
      id: '2',
      name: 'Methotrexate',
      activeIngredient: 'Methotrexate',
      riskLevel: 'critical',
      interactionCount: 38,
    ),
    DangerousDrugModel(
      id: '3',
      name: 'Digoxin',
      activeIngredient: 'Digoxin',
      riskLevel: 'high',
      interactionCount: 29,
    ),
    DangerousDrugModel(
      id: '4',
      name: 'Lithium',
      activeIngredient: 'Lithium Carbonate',
      riskLevel: 'high',
      interactionCount: 24,
    ),
  ];

  late List<DrugUIModel> recentDrugs;

  @override
  void initState() {
    super.initState();
    recentDrugs = [
      DrugUIModel(
        id: '1',
        tradeNameEn: 'Panadol Extra',
        tradeNameAr: 'بانادول اكسترا',
        activeIngredient: 'Paracetamol + Caffeine',
        form: 'tablet',
        currentPrice: 45.50,
        oldPrice: 52.00,
        company: 'GSK',
        isNew: true,
      ),
      DrugUIModel(
        id: '2',
        tradeNameEn: 'Augmentin 1g',
        tradeNameAr: 'اوجمنتين ١ جرام',
        activeIngredient: 'Amoxicillin + Clavulanic Acid',
        form: 'tablet',
        currentPrice: 185.00,
        company: 'GSK',
        isPopular: true,
        hasInteraction: true,
      ),
      DrugUIModel(
        id: '3',
        tradeNameEn: 'Cataflam 50mg',
        tradeNameAr: 'كتافلام ٥٠ مجم',
        activeIngredient: 'Diclofenac Potassium',
        form: 'tablet',
        currentPrice: 67.25,
        oldPrice: 60.00,
        company: 'Novartis',
      ),
    ];
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
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
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // Search Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        HomeSearchBar(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SearchResultsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Quick Stats
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.successSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    LucideIcons.trendingUp,
                                    size: 20,
                                    color: AppColors.success,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Today's Updates",
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
                                  borderRadius: BorderRadius.circular(6),
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

                  // Categories Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(
                      title: "Medical Specialties",
                      subtitle: "Browse by category",
                      icon: const Icon(LucideIcons.pill),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130, // Updated height to fit new card
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder:
                          (context, index) => CategoryCard(
                            category: categories[index],
                            isRTL: isRTL,
                          ),
                    ),
                  ),

                  // Dangerous Drugs Section
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(
                      title: "High-Risk Drugs",
                      subtitle: "Drugs with severe interactions",
                      icon: const Icon(LucideIcons.alertTriangle),
                      iconBgColor: AppColors.dangerSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 140, // Height for DangerousDrugCard
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: dangerousDrugs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder:
                          (context, index) => DangerousDrugCard(
                            drug: dangerousDrugs[index],
                            isRTL: isRTL,
                          ),
                    ),
                  ),

                  // Recently Added Section
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(
                      title: "Recently Added",
                      subtitle: "New drugs this week",
                      icon: const Icon(LucideIcons.sparkles),
                      iconBgColor: AppColors.successSoft,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics:
                        const NeverScrollableScrollPhysics(), // Nested scroll
                    shrinkWrap: true,
                    itemCount: recentDrugs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final drug = recentDrugs[index];
                      // Create copy with isFavorite state
                      final drugWithState = DrugUIModel(
                        id: drug.id,
                        tradeNameEn: drug.tradeNameEn,
                        tradeNameAr: drug.tradeNameAr,
                        activeIngredient: drug.activeIngredient,
                        form: drug.form,
                        currentPrice: drug.currentPrice,
                        oldPrice: drug.oldPrice,
                        company: drug.company,
                        isNew: drug.isNew,
                        isPopular: drug.isPopular,
                        hasInteraction: drug.hasInteraction,
                        isFavorite: _favorites.contains(drug.id),
                      );

                      return DrugCard(
                        drug: drugWithState,
                        isRTL: isRTL,
                        onFavoriteToggle: _toggleFavorite,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DrugDetailsScreen(),
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
