import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/constants/design_tokens.dart';
import 'package:mediswitch/core/utils/animation_helpers.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/screens/details/drug_details_screen.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/utils/drug_entity_converter.dart';
import 'package:mediswitch/presentation/widgets/home/drug_card.dart';
import 'package:mediswitch/presentation/widgets/home_search_bar.dart';
import 'package:mediswitch/presentation/widgets/search_filters_sheet.dart';
import 'package:provider/provider.dart';

class SearchResultsScreen extends StatefulWidget {
  final String initialQuery;
  final VoidCallback? onBack;

  const SearchResultsScreen({super.key, this.initialQuery = '', this.onBack});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late TextEditingController _searchController;
  late ScrollController _scrollController;
  Timer? _debounce;
  bool _isLoadingMore = false;
  FilterState _filters = const FilterState();

  final filterOptions = [
    {'id': '', 'label': 'All'},
    {'id': 'Tablet', 'label': 'Tablets'},
    {'id': 'Syrup', 'label': 'Syrups'},
    {'id': 'Injection', 'label': 'Injections'},
    {'id': 'Cream', 'label': 'Creams'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery.isNotEmpty) {
        _performSearch(widget.initialQuery);
      } else {
        context.read<MedicineProvider>().updateSearchQuery('');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Load more when 90% scrolled
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    final provider = context.read<MedicineProvider>();
    if (!provider.hasMoreItems || provider.isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    await provider.loadMoreResults();

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    context.read<MedicineProvider>().updateSearchQuery(query);
  }

  void _onFilterChanged(String filterId) {
    context.read<MedicineProvider>().updateFilters(dosageForm: filterId);
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SearchFiltersSheet(
            filters: _filters,
            onApplyFilters: (newFilters) {
              setState(() {
                _filters = newFilters;
              });
              // Apply filters to provider
              // TODO: Implement filter logic in provider
            },
            isRTL: Directionality.of(context) == TextDirection.rtl,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header + Search + Filters (مثبت بشكل طبيعي)
          ColoredBox(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: AppSpacing.paddingLG,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed:
                              widget.onBack ??
                              () => Navigator.of(context).pop(),
                          icon: const Icon(LucideIcons.arrowLeft),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).appColors.accent,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: HomeSearchBar(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Filter Button
                        IconButton(
                          onPressed: _showFilters,
                          icon: const Icon(LucideIcons.slidersHorizontal),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).appColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Pills
                  Consumer<MedicineProvider>(
                    builder: (context, provider, _) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ).copyWith(bottom: AppSpacing.md),
                        child: Row(
                          children:
                              filterOptions.map((f) {
                                final isActive =
                                    provider.selectedDosageForm == f['id'];
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.sm,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _onFilterChanged(f['id']!),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                        vertical: AppSpacing.sm,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isActive
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                                : Theme.of(
                                                  context,
                                                ).appColors.accent,
                                        borderRadius: AppRadius.circularFull,
                                      ),
                                      child: Text(
                                        f['label']!,
                                        style: TextStyle(
                                          color:
                                              isActive
                                                  ? Colors.white
                                                  : Theme.of(
                                                    context,
                                                  ).appColors.mutedForeground,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Results
          Expanded(
            child: Consumer<MedicineProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(provider.error),
                        TextButton(
                          onPressed:
                              () => _performSearch(_searchController.text),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }

                final filteredDrugs = provider.medicines;

                if (filteredDrugs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: 64,
                          color: Theme.of(context).appColors.mutedForeground,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "No results found",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "Try adjusting your search",
                          style: TextStyle(
                            color: Theme.of(context).appColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${filteredDrugs.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: ' results',
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).appColors.mutedForeground,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            filteredDrugs.length + (_isLoadingMore ? 1 : 0),
                        separatorBuilder:
                            (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          // Loading indicator at the end
                          if (index == filteredDrugs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final drug = filteredDrugs[index];
                          final isFav = provider.isFavorite(drug);
                          final uiModel = drugEntityToUIModel(
                            drug,
                            isFavorite: isFav,
                          );

                          return FadeSlideAnimation(
                            delay: StaggeredAnimationHelper.delayFor(index),
                            child: DrugCard(
                              drug: uiModel,
                              onFavoriteToggle: (drug) {
                                provider.toggleFavorite(filteredDrugs[index]);
                              },
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder:
                                        (_) => DrugDetailsScreen(drug: drug),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
