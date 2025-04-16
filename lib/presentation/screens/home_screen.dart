import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart';
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
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../services/ad_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdService _adService = locator<AdService>();
  final FileLoggerService _logger = locator<FileLoggerService>();
  final ScrollController _scrollController =
      ScrollController(); // Re-add ScrollController

  @override
  void initState() {
    super.initState();
    _logger.i("HomeScreen: initState called.");
    _scrollController.addListener(_onScroll); // Re-add listener
  }

  @override
  void dispose() {
    _logger.i("HomeScreen: dispose called.");
    _scrollController.removeListener(_onScroll); // Re-add listener removal
    _scrollController.dispose(); // Re-add dispose
    super.dispose();
  }

  // Re-add _onScroll method for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        context.read<MedicineProvider>().hasMoreItems &&
        !context.read<MedicineProvider>().isLoadingMore &&
        !context.read<MedicineProvider>().isLoading) {
      _logger.i("HomeScreen: Reached near bottom, calling loadMoreDrugs...");
      try {
        context.read<MedicineProvider>().loadMoreDrugs();
      } catch (e, s) {
        _logger.e("HomeScreen: Error calling loadMoreDrugs", e, s);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("HomeScreen: Building widget...");
    final medicineProvider = context.watch<MedicineProvider>();
    final isLoading = medicineProvider.isLoading;
    final isLoadingMore =
        medicineProvider.isLoadingMore; // Re-add isLoadingMore
    final error = medicineProvider.error;
    final displayedMedicines = medicineProvider.filteredMedicines;
    // Re-add hasMoreItems to log
    _logger.d(
      "HomeScreen: State - isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: '$error', displayedMedicines: ${displayedMedicines.length}, hasMore: ${medicineProvider.hasMoreItems}",
    );

    return Scaffold(
      body: Column(
        children: [
          const HomeHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                _logger.i("HomeScreen: RefreshIndicator triggered.");
                // Reload all data, including the full list for local filtering
                return context.read<MedicineProvider>().loadInitialData(
                  forceUpdate: true,
                );
              },
              // Update loading check
              child:
                  isLoading &&
                          displayedMedicines.isEmpty &&
                          medicineProvider.recentlyUpdatedDrugs.isEmpty &&
                          medicineProvider.popularDrugs.isEmpty
                      ? _buildLoadingIndicator()
                      // Pass isLoadingMore back to _buildContent
                      : _buildContent(
                        context,
                        medicineProvider,
                        displayedMedicines,
                        isLoading,
                        isLoadingMore,
                        error,
                      ),
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    _logger.v("HomeScreen: Building loading indicator.");
    return const Center(child: CircularProgressIndicator());
  }

  // Re-add isLoadingMore parameter
  Widget _buildContent(
    BuildContext context,
    MedicineProvider medicineProvider,
    List<DrugEntity> displayedMedicines,
    bool isLoading,
    bool isLoadingMore,
    String error,
  ) {
    _logger.v("HomeScreen: Building main content CustomScrollView.");

    return CustomScrollView(
      controller: _scrollController, // Re-add controller
      slivers: [
        SliverToBoxAdapter(child: const SearchBarButton()),
        SliverToBoxAdapter(child: _buildCategoriesSection(context)),

        // --- Recently Updated Section ---
        if (medicineProvider.recentlyUpdatedDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildHorizontalDrugList(
              context,
              title: "أدوية محدثة مؤخراً",
              drugs: medicineProvider.recentlyUpdatedDrugs,
              onViewAll: () {
                _logger.i("HomeScreen: View All Recent tapped.");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchScreen(initialQuery: ''),
                  ),
                );
              },
            ),
          ),

        // --- Popular Drugs Section ---
        if (medicineProvider.popularDrugs.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildHorizontalDrugList(
              context,
              title: "الأكثر بحثاً",
              drugs: medicineProvider.popularDrugs,
              isPopular: true, // Mark these drugs as popular
              onViewAll: () {
                _logger.i("HomeScreen: View All Popular tapped.");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchScreen(initialQuery: ''),
                  ),
                );
              },
            ),
          ),

        // --- All Drugs Section Header ---
        SliverToBoxAdapter(
          child: Padding(
            // Apply standard horizontal padding and specific bottom margin (mb-4 -> bottom: 16.0)
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 24.0, // Keep existing top padding
              bottom: 16.0, // Add bottom padding (mb-4)
            ),
            child: SectionHeader(
              title: 'جميع الأدوية',
              padding:
                  EdgeInsets.zero, // Remove default padding from SectionHeader
            ),
          ),
        ),

        // --- All Drugs List ---
        if (displayedMedicines.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final drug = displayedMedicines[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: DrugCard(
                    drug: drug,
                    type: DrugCardType.detailed,
                    onTap: () => _navigateToDetails(context, drug),
                    // isPopular: drug.isPopular, // Assuming DrugEntity has isPopular flag
                    // isAlternative: drug.isAlternative, // Assuming DrugEntity has isAlternative flag
                  ),
                ).animate().fadeIn(delay: (index % 10 * 50).ms);
              }, childCount: displayedMedicines.length),
            ),
          )
        // Show empty/error state only if not loading more
        else if (!isLoadingMore)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildListFooter(
              context,
              medicineProvider,
              displayedMedicines,
              isLoading,
              isLoadingMore,
              error,
            ), // Pass isLoadingMore
          ),

        // --- Loading More Indicator / End Message ---
        // Show footer if the list is not empty (it contains either loading or end message)
        if (displayedMedicines.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildListFooter(
              context,
              medicineProvider,
              displayedMedicines,
              isLoading,
              isLoadingMore,
              error,
            ), // Pass isLoadingMore
          ),
      ],
    );
  }

  // Helper for building horizontal drug lists
  Widget _buildHorizontalDrugList(
    BuildContext context, {
    required String title,
    required List<DrugEntity> drugs,
    VoidCallback? onViewAll,
    bool isPopular = false, // Add isPopular flag
  }) {
    return HorizontalListSection(
      title: title,
      listHeight: 190,
      onViewAll: onViewAll,
      // headerPadding removed, handled internally
      listPadding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      children:
          drugs
              .map(
                (drug) => DrugCard(
                  drug: drug,
                  type: DrugCardType.thumbnail,
                  isPopular: isPopular, // Pass the flag here
                  onTap: () => _navigateToDetails(context, drug),
                ).animate().fadeIn(delay: (drugs.indexOf(drug) * 80).ms),
              )
              .toList(),
    );
  }

  // Re-add isLoadingMore parameter
  Widget _buildListFooter(
    BuildContext context,
    MedicineProvider provider,
    List<DrugEntity> medicines,
    bool isLoading,
    bool isLoadingMore,
    String error,
  ) {
    if (isLoadingMore) {
      _logger.v("HomeScreen: Building loading more indicator at end of list.");
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (!provider.hasMoreItems && medicines.isNotEmpty) {
      // Re-add hasMoreItems check
      _logger.v("HomeScreen: Building 'end of list' message.");
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Center(
          child: Text(
            'وصلت إلى نهاية القائمة',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
          ),
        ),
      );
    } else if (medicines.isEmpty && !isLoading && error.isNotEmpty) {
      return _buildErrorWidget(context, error);
    } else if (medicines.isEmpty && !isLoading && error.isEmpty) {
      return _buildEmptyListMessage(context, provider);
    } else {
      return const SizedBox(height: 16); // Default bottom padding
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    return const SearchBarButton();
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = context.watch<MedicineProvider>().categories;
    _logger.v(
      "HomeScreen: Building categories section with ${categories.length} categories.",
    );
    final categoryIcons = {
      /* ... same icons map ... */
      'مسكنات الألم': LucideIcons.pill,
      'مضادات حيوية': LucideIcons.syringe,
      'أمراض القلب': LucideIcons.heartPulse,
      'أمراض مزمنة': LucideIcons.activity,
      'فيتامينات ومعادن': LucideIcons.leaf,
      'أدوية الجهاز الهضمي': LucideIcons.soup,
      'أدوية الجهاز التنفسي': LucideIcons.wind,
      'أدوية جلدية': LucideIcons.sprayCan,
      'أدوية حساسية': LucideIcons.shieldAlert,
      'أدوية أعصاب': LucideIcons.brain,
      'مضادات الفطريات': LucideIcons.bug,
      'أدوية العيون': LucideIcons.eye,
      'أدوية الأنف والأذن والحنجرة': LucideIcons.ear,
      'أدوية النساء': LucideIcons.baby,
      'أدوية السكر': LucideIcons.droplet,
      'أدوية الضغط': LucideIcons.gauge,
    };

    if (categories.isEmpty && context.watch<MedicineProvider>().isLoading) {
      return const SizedBox(
        height: 115,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (categories.isEmpty) {
      _logger.w("HomeScreen: No categories found to display.");
      return const SizedBox.shrink();
    }

    return HorizontalListSection(
      title: 'الفئات الطبية',
      listHeight: 105,
      // headerPadding removed
      listPadding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      children:
          categories.map((categoryName) {
            return CategoryCard(
                  key: ValueKey(categoryName),
                  name: categoryName,
                  iconData: categoryIcons[categoryName] ?? LucideIcons.tag,
                  onTap: () {
                    _logger.i("HomeScreen: Category tapped: $categoryName");
                    _adService.incrementUsageCounterAndShowAdIfNeeded();
                    // Use setCategory for single category selection
                    context.read<MedicineProvider>().setCategory(categoryName);
                  },
                )
                .animate()
                .scale(
                  delay: (categories.indexOf(categoryName) * 100).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                )
                .fadeIn(
                  delay: (categories.indexOf(categoryName) * 100).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut,
                );
          }).toList(),
    );
  }

  void _navigateToDetails(BuildContext context, DrugEntity drug) {
    _logger.i("HomeScreen: Navigating to details for drug: ${drug.tradeName}");
    _adService.incrementUsageCounterAndShowAdIfNeeded();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrugDetailsScreen(drug: drug)),
    );
  }

  Widget _buildEmptyListMessage(
    BuildContext context,
    MedicineProvider provider,
  ) {
    // Check selectedCategory (single string)
    final bool filtersActive =
        provider.searchQuery.isNotEmpty || provider.selectedCategory.isNotEmpty;
    _logger.v(
      "HomeScreen: Building empty list message. Filters active: $filtersActive",
    );
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 64,
            color: Theme.of(context).hintColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            filtersActive
                ? 'لا توجد نتائج تطابق الفلاتر الحالية.'
                : 'لا توجد أدوية لعرضها حالياً.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          if (!filtersActive)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'حاول سحب الشاشة للأسفل للتحديث.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    _logger.w("HomeScreen: Building error widget: $error");
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 64.0, horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: Theme.of(context).colorScheme.error,
            size: 64.0,
          ),
          const SizedBox(height: 16.0),
          Text(
            'حدث خطأ',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            error,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error.withOpacity(0.8),
              fontSize: 16.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24.0),
          ElevatedButton.icon(
            icon: Icon(LucideIcons.refreshCw),
            label: const Text('إعادة المحاولة'),
            onPressed: () {
              _logger.i("HomeScreen: Retry button pressed.");
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
