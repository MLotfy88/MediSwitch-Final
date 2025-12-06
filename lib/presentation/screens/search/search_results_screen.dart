import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../widgets/home/drug_card.dart';
import '../../widgets/home_search_bar.dart';
import '../details/drug_details_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final VoidCallback? onBack;

  const SearchResultsScreen({
    Key? key,
    this.initialQuery = 'Panadol',
    this.onBack,
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;
  String activeFilter = 'all';
  final Set<String> favorites = {};

  final filterOptions = [
    {'id': 'all', 'label': 'All'},
    {'id': 'tablet', 'label': 'Tablets'},
    {'id': 'syrup', 'label': 'Syrups'},
    {'id': 'injection', 'label': 'Injections'},
    {'id': 'cream', 'label': 'Creams'},
  ];

  final List<DrugUIModel> allDrugs = [
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
      tradeNameEn: 'Panadol Advance',
      tradeNameAr: 'بانادول ادفانس',
      activeIngredient: 'Paracetamol 500mg',
      form: 'tablet',
      currentPrice: 38.00,
      company: 'GSK',
      isPopular: true,
    ),
    DrugUIModel(
      id: '3',
      tradeNameEn: 'Panadol Cold & Flu',
      tradeNameAr: 'بانادول كولد اند فلو',
      activeIngredient: 'Paracetamol + Pseudoephedrine',
      form: 'tablet',
      currentPrice: 55.00,
      company: 'GSK',
      hasInteraction: true,
    ),
    DrugUIModel(
      id: '4',
      tradeNameEn: 'Panadol Night',
      tradeNameAr: 'بانادول نايت',
      activeIngredient: 'Paracetamol + Diphenhydramine',
      form: 'tablet',
      currentPrice: 62.50,
      oldPrice: 68.00,
      company: 'GSK',
    ),
    DrugUIModel(
      id: '5',
      tradeNameEn: 'Panadol Syrup',
      tradeNameAr: 'بانادول شراب',
      activeIngredient: 'Paracetamol 120mg/5ml',
      form: 'syrup',
      currentPrice: 28.00,
      company: 'GSK',
      isNew: true,
    ),
    DrugUIModel(
      id: '6',
      tradeNameEn: 'Brufen 400mg',
      tradeNameAr: 'بروفين ٤٠٠ مجم',
      activeIngredient: 'Ibuprofen',
      form: 'tablet',
      currentPrice: 75.00,
      company: 'Pfizer',
      isPopular: true,
    ),
    DrugUIModel(
      id: '7',
      tradeNameEn: 'Voltaren Gel',
      tradeNameAr: 'فولتارين جل',
      activeIngredient: 'Diclofenac Sodium',
      form: 'cream',
      currentPrice: 120.00,
      oldPrice: 135.00,
      company: 'Novartis',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    // Filter Logic
    final filteredDrugs =
        allDrugs.where((d) {
          if (activeFilter != 'all' && d.form != activeFilter) return false;
          final query = _searchController.text.toLowerCase();
          if (query.isNotEmpty) {
            return d.tradeNameEn.toLowerCase().contains(query) ||
                d.tradeNameAr.contains(query) ||
                d.activeIngredient.toLowerCase().contains(query);
          }
          return true;
        }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header + Search + Filters
          Container(
            color: AppColors.surface.withOpacity(
              0.95,
            ), // backdrop blur simulated
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed:
                              widget.onBack ??
                              () => Navigator.of(context).pop(),
                          icon: const Icon(LucideIcons.arrowLeft),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: HomeSearchBar(
                            controller: _searchController,
                            onChanged: (v) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Pills
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children:
                          filterOptions.map((f) {
                            final isActive = activeFilter == f['id'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap:
                                    () =>
                                        setState(() => activeFilter = f['id']!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isActive
                                            ? AppColors.primary
                                            : AppColors.accent,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    f['label']!,
                                    style: TextStyle(
                                      color:
                                          isActive
                                              ? Colors.white
                                              : AppColors.foreground,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Results Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${filteredDrugs.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text: ' results',
                        style: TextStyle(color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                if (activeFilter != 'all')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'Filters active',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // List
          Expanded(
            child:
                filteredDrugs.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: const BoxDecoration(
                              color: AppColors.muted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              size: 40,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "No results found",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Text(
                            "Try adjusting your search",
                            style: TextStyle(color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredDrugs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final drug = filteredDrugs[index];
                        return DrugCard(
                          drug: DrugUIModel(
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
                            isFavorite: favorites.contains(drug.id),
                          ),
                          isRTL: isRTL,
                          onFavoriteToggle:
                              (id) => setState(() {
                                if (favorites.contains(id))
                                  favorites.remove(id);
                                else
                                  favorites.add(id);
                              }),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DrugDetailsScreen(),
                              ),
                            );
                          },
                        ).animate().fadeIn(delay: (50 * index).ms);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
