import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui' as ui; // For TextDirection

import '../../domain/entities/drug_entity.dart';
import '../bloc/medicine_provider.dart';
import '../widgets/drug_card.dart';
import '../widgets/filter_end_drawer.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import 'drug_details_screen.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../../core/constants/app_spacing.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  // Timer? _debounce; // Debounce removed in favor of manual submission
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logger.i(
      "SearchScreen: +++++ initState +++++. Initial query: '${widget.initialQuery}'",
    );
    _searchController.text = widget.initialQuery;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<MedicineProvider>();
        bool categoryChanged = false;
        bool queryChanged = false;

        if (widget.initialCategory != null &&
            widget.initialCategory!.isNotEmpty &&
            provider.selectedCategory != widget.initialCategory) {
          provider.setCategory(widget.initialCategory!, triggerSearch: false);
          categoryChanged = true;
        } else if ((widget.initialCategory == null ||
                widget.initialCategory!.isEmpty) &&
            provider.selectedCategory.isNotEmpty) {
          provider.setCategory('', triggerSearch: false);
          categoryChanged = true;
        }

        if (widget.initialQuery.isNotEmpty &&
            provider.searchQuery != widget.initialQuery) {
          provider.setSearchQuery(widget.initialQuery, triggerSearch: false);
          queryChanged = true;
        } else if (widget.initialQuery.isEmpty &&
            provider.searchQuery.isNotEmpty) {
          provider.setSearchQuery('', triggerSearch: false);
          queryChanged = true;
        }

        if (categoryChanged || queryChanged) {
          provider.triggerSearch();
        }
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _logger.i("SearchScreen: ----- dispose -----");
    // _debounce?.cancel(); // No debounce to cancel
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Simplified: No debounce/listener. Search triggered explicitly.
  void _performSearch() {
    final query = _searchController.text;
    _logger.i("SearchScreen: Executing search for '$query'");
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    context.read<MedicineProvider>().setSearchQuery(query);
    // Provider's setSearchQuery usually triggers filteredMedicines update if wired correctly.
    // If setCategory/setQuery has triggerSearch=true default, it works.
  }

  void _onScroll() {
    final provider = context.read<MedicineProvider>();
    if (!_scrollController.hasClients) return; // Guard clause
    final currentPixels = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final triggerPoint = maxScroll - 300;
    final bool isNearBottom = currentPixels >= triggerPoint && maxScroll > 0;
    final bool canLoadMore =
        provider.hasMoreItems && !provider.isLoadingMore && !provider.isLoading;

    if (isNearBottom && canLoadMore) {
      try {
        provider.loadMoreDrugs();
      } catch (e, s) {
        _logger.e("SearchScreen: Error calling loadMoreDrugs", e, s);
      }
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
    _logger.i("SearchScreen: >>>>> build ENTRY <<<<<");
    try {
      final l10n = AppLocalizations.of(context)!;
      final provider = context.watch<MedicineProvider>();
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      return Scaffold(
        key: _scaffoldKey,
        endDrawer: const FilterEndDrawer(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          onPressed: () {
            // FAB acting as search trigger or scroll to top if desired, but user asked for "search button".
            // A floating search action typically means "Execute Search".
            _performSearch();
          },
          child: const Icon(LucideIcons.search),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: <Widget>[
                    SliverAppBar(
                      backgroundColor: colorScheme.surface,
                      foregroundColor: colorScheme.onSurfaceVariant,
                      elevation: 0,
                      pinned: true,
                      floating: true,
                      leading: IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                        onPressed: () => Navigator.maybePop(context),
                        tooltip: l10n.backTooltip,
                      ),
                      titleSpacing: 0,
                      title: TextField(
                        controller: _searchController,
                        autofocus: false, // DISABLED AUTOFOCUS as requested
                        textInputAction:
                            TextInputAction
                                .search, // Show Search key on keyboard
                        onSubmitted:
                            (_) =>
                                _performSearch(), // Trigger on keyboard action
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 16,
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
                                      // Optionally clear results immediately or wait for search
                                    },
                                    splashRadius: 18,
                                  )
                                  : null,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        style: theme.textTheme.bodyLarge,
                      ),
                      actions: [
                        TextButton(
                          onPressed: _openFilterDrawer,
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(AppSpacing.small),
                            minimumSize: Size.zero,
                          ),
                          child: const Icon(LucideIcons.filter, size: 20),
                        ),
                        AppSpacing.gapHSmall,
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(1.0),
                        child: Container(
                          color: colorScheme.outline,
                          height: 1.0,
                        ),
                      ),
                    ),
                    _buildResultsListSliver(context, provider, l10n),
                  ],
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        ),
      );
    } catch (e, s) {
      _logger.e("SearchScreen: >>>>> CRITICAL ERROR DURING BUILD <<<<<", e, s);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error building SearchScreen:\n$e\n\n$s',
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textDirection: ui.TextDirection.ltr,
            ),
          ),
        ),
      );
    } finally {
      _logger.i("SearchScreen: >>>>> build EXIT <<<<<");
    }
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
    } else if (provider.filteredMedicines.isEmpty &&
        provider.searchQuery.isNotEmpty) {
      return SliverFillRemaining(
        child: _buildEmptySearchMessage(context, l10n),
        hasScrollBody: false,
      );
    } else if (provider.filteredMedicines.isEmpty &&
        provider.searchQuery.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            l10n.startSearchingPrompt,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ),
        hasScrollBody: false,
      );
    }

    return SliverPadding(
      padding: AppSpacing.edgeInsetsAllLarge,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < provider.filteredMedicines.length) {
              final drug = provider.filteredMedicines[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.large),
                child: DrugCard(
                  drug: drug,
                  type: DrugCardType.detailed,
                  onTap: () => _navigateToDetails(context, drug),
                ),
              );
            } else if (provider.isLoadingMore) {
              return Padding(
                padding: AppSpacing.edgeInsetsVLarge,
                child: const Center(child: CircularProgressIndicator()),
              );
            } else if (!provider.hasMoreItems) {
              return Padding(
                padding: AppSpacing.edgeInsetsVLarge,
                child: Center(
                  child: Text(
                    l10n.endOfList,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
          childCount:
              provider.filteredMedicines.length +
              (provider.isLoadingMore || !provider.hasMoreItems ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildEmptySearchMessage(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxlarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 48,
              color: theme.hintColor.withOpacity(0.7),
            ),
            AppSpacing.gapVLarge,
            Text(l10n.noResultsFoundTitle, style: theme.textTheme.titleLarge),
            AppSpacing.gapVSmall,
            Text(
              l10n.noResultsFoundSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
