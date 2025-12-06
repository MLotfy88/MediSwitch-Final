import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../domain/entities/drug_entity.dart';
import '../../presentation/theme/app_colors.dart'; // Import AppColors
import '../bloc/medicine_provider.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/drug_card.dart';
import '../widgets/filter_end_drawer.dart';
import 'drug_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  final String? initialCategory;
  const SearchScreen({super.key, this.initialQuery = '', this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FileLoggerService _logger = locator<FileLoggerService>();
  final AdService _adService = locator<AdService>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MedicineProvider>();
        bool changed = false;

        // Handle initial category
        if (widget.initialCategory != null &&
            widget.initialCategory!.isNotEmpty &&
            provider.selectedCategory != widget.initialCategory) {
          provider.setCategory(widget.initialCategory!, triggerSearch: false);
          changed = true;
        }

        // Handle initial query
        if (widget.initialQuery.isNotEmpty &&
            provider.searchQuery != widget.initialQuery) {
          provider.setSearchQuery(widget.initialQuery, triggerSearch: false);
          changed = true;
        }

        if (changed) {
          provider.triggerSearch();
        }
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text;
    FocusScope.of(context).unfocus();
    context.read<MedicineProvider>().setSearchQuery(query);
  }

  void _onScroll() {
    final provider = context.read<MedicineProvider>();
    if (!_scrollController.hasClients) return;
    final currentPixels = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final triggerPoint = maxScroll - 300;

    if (currentPixels >= triggerPoint &&
        provider.hasMoreItems &&
        !provider.isLoadingMore &&
        !provider.isLoading) {
      provider.loadMoreDrugs();
    }
  }

  void _openFilterDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _navigateToDetails(BuildContext context, DrugEntity drug) {
    _adService.incrementUsageCounterAndShowAdIfNeeded();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrugDetailsScreen(drug: drug)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<MedicineProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const FilterEndDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: <Widget>[
                  // Custom AppBar with Styled Buttons
                  SliverAppBar(
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.onSurface,
                    elevation: 0,
                    pinned: true,
                    floating: true,
                    toolbarHeight: 70, // Increased height for better spacing
                    leadingWidth: 60,
                    leading: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 16,
                        top: 8,
                        bottom: 8,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, size: 20),
                          color: AppColors.primary,
                          onPressed: () => Navigator.maybePop(context),
                          tooltip: l10n.backTooltip,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    title: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _performSearch(),
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        border: InputBorder.none,
                        // Add background to search bar for contrast if needed, or keep clean
                        prefixIcon: Icon(
                          LucideIcons.search,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    provider.setSearchQuery('');
                                  },
                                )
                                : null,
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: 16,
                          top: 8,
                          bottom: 8,
                        ),
                        child: InkWell(
                          onTap: _openFilterDrawer,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.filter,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                // const SizedBox(width: 8),
                                // Text(
                                //   "Filter", // Localize this
                                //   style: TextStyle(
                                //     color: AppColors.primary,
                                //     fontWeight: FontWeight.w600,
                                //     fontSize: 14,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Filter Pills Section
                  SliverToBoxAdapter(
                    child: _buildFilterPills(context, provider),
                  ),

                  // Results Count
                  if (!provider.isLoading &&
                      provider.filteredMedicines.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          "${provider.filteredMedicines.length} ${isRTL ? 'نتائج' : 'results'}", // Localize fully
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                  // Results List
                  _buildResultsListSliver(context, provider, l10n),
                ],
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPills(BuildContext context, MedicineProvider provider) {
    final pills = [
      {'labelEn': 'All', 'labelAr': 'الكل', 'value': ''},
      {'labelEn': 'Tablet', 'labelAr': 'أقراص', 'value': 'Tablet'},
      {'labelEn': 'Syrup', 'labelAr': 'شراب', 'value': 'Syrup'},
      {'labelEn': 'Injection', 'labelAr': 'حقن', 'value': 'Injection'},
      {'labelEn': 'Cream', 'labelAr': 'كريم', 'value': 'Cream'},
      {'labelEn': 'Drops', 'labelAr': 'قطرة', 'value': 'Drops'},
    ];

    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final pill = pills[index];
          final value = pill['value']!;
          final label = isRTL ? pill['labelAr']! : pill['labelEn']!;
          final isSelected = provider.selectedDosageForm == value;
          final colorScheme = Theme.of(context).colorScheme;

          return InkWell(
            onTap: () {
              provider.setDosageForm(isSelected ? '' : value);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary : AppColors.accent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? colorScheme.primary : Colors.transparent,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsListSliver(
    BuildContext context,
    MedicineProvider provider,
    AppLocalizations l10n,
  ) {
    if (provider.isLoading && provider.filteredMedicines.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
        hasScrollBody: false,
      );
    } else if (provider.error.isNotEmpty &&
        provider.filteredMedicines.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            l10n.errorMessage(provider.error),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        hasScrollBody: false,
      );
    } else if (provider.filteredMedicines.isEmpty) {
      // Show empty state for no results
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.search,
                size: 48,
                color: Theme.of(context).hintColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noResultsFoundTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
        hasScrollBody: false,
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < provider.filteredMedicines.length) {
              final drug = provider.filteredMedicines[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DrugCard(
                  drug: drug,
                  type: DrugCardType.detailed,
                  onTap: () => _navigateToDetails(context, drug),
                ),
              );
            } else if (provider.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            } else {
              // End of list spacer
              return const SizedBox(height: 20);
            }
          },
          childCount:
              provider.filteredMedicines.length +
              (provider.isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }
}
