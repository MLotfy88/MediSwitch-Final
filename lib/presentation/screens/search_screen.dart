import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/drug_entity.dart';
import '../bloc/medicine_provider.dart';
import '../widgets/drug_card.dart';
// import '../widgets/filter_bottom_sheet.dart'; // Will be replaced by drawer
import '../widgets/filter_end_drawer.dart'; // Import the new drawer
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import 'drug_details_screen.dart';
import '../services/ad_service.dart';
import '../widgets/banner_ad_widget.dart';
import '../../core/constants/app_spacing.dart'; // Import spacing constants

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({super.key, this.initialQuery = ''});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FileLoggerService _logger = locator<FileLoggerService>();
  final AdService _adService = locator<AdService>();
  Timer? _debounce;
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Key for drawer
  final ScrollController _scrollController =
      ScrollController(); // Add ScrollController for pagination

  @override
  void initState() {
    super.initState();
    _logger.i(
      "SearchScreen: +++++ initState +++++. Initial query: '${widget.initialQuery}'", // Lifecycle Log
    );
    _searchController.text = widget.initialQuery;
    // Trigger initial search if query is provided
    if (widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<MedicineProvider>().setSearchQuery(widget.initialQuery);
        }
      });
    }
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll); // Add listener
  }

  @override
  void dispose() {
    _logger.i("SearchScreen: ----- dispose -----"); // Lifecycle Log
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll); // Remove listener
    _scrollController.dispose(); // Dispose controller
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Only call setSearchQuery if the query has actually changed
        final newQuery = _searchController.text;
        final currentProviderQuery =
            context.read<MedicineProvider>().searchQuery;
        if (newQuery != currentProviderQuery) {
          _logger.i(
            "SearchScreen: Debounced search triggered with new query: '$newQuery'",
          );
          context.read<MedicineProvider>().setSearchQuery(newQuery);
        }
      }
    });
  }

  // Add _onScroll method for pagination (adapted from HomeScreen)
  void _onScroll() {
    final provider = context.read<MedicineProvider>();
    final currentPixels = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    // Adjust trigger point if needed, 300 pixels from bottom seems reasonable
    final triggerPoint = maxScroll - 300;
    final bool isNearBottom =
        currentPixels >= triggerPoint && maxScroll > 0; // Ensure maxScroll > 0
    final bool canLoadMore =
        provider.hasMoreItems && !provider.isLoadingMore && !provider.isLoading;
    final shouldLoadMore = isNearBottom && canLoadMore;

    _logger.v(
      "SearchScreen _onScroll: Pixels=${currentPixels.toStringAsFixed(1)}, MaxScroll=${maxScroll.toStringAsFixed(1)}, TriggerAt=${triggerPoint.toStringAsFixed(1)}, IsNearBottom=$isNearBottom, CanLoadMore=$canLoadMore, ShouldLoad=$shouldLoadMore",
    );

    if (shouldLoadMore) {
      _logger.i("SearchScreen: Reached near bottom, calling loadMoreDrugs...");
      // Use try-catch just in case
      try {
        provider.loadMoreDrugs();
      } catch (e, s) {
        _logger.e("SearchScreen: Error calling loadMoreDrugs", e, s);
      }
    }
  }

  void _openFilterDrawer() {
    _logger.i("SearchScreen: Filter button tapped, opening end drawer.");
    _scaffoldKey.currentState?.openEndDrawer(); // Use key to open drawer
  }

  void _navigateToDetails(BuildContext context, DrugEntity drug) {
    _logger.i(
      "SearchScreen: Navigating to details for drug: ${drug.tradeName}",
    );
    _adService.incrementUsageCounterAndShowAdIfNeeded();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrugDetailsScreen(drug: drug)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("SearchScreen: >>>>> build ENTRY <<<<<"); // Updated Log
    try {
      // Add try block here
      final provider = context.watch<MedicineProvider>();
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;
      _logger.d(
        "SearchScreen BUILD State: isLoading=${provider.isLoading}, error='${provider.error}', results=${provider.filteredMedicines.length}",
      ); // Log state

      // Log before returning Scaffold
      _logger.v(
        "SearchScreen: build - State read successfully. Returning Scaffold...",
      );

      return Scaffold(
        key: _scaffoldKey, // Assign key
        endDrawer: const FilterEndDrawer(), // Add the drawer
        // Wrap the body content with SafeArea
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  // Use CustomScrollView for SliverAppBar
                  controller: _scrollController, // Assign controller
                  slivers: <Widget>[
                    SliverAppBar(
                      backgroundColor: colorScheme.surface, // bg-card
                      foregroundColor:
                          colorScheme.onSurfaceVariant, // text-muted-foreground
                      elevation: 0, // Remove shadow
                      pinned: true, // Make AppBar sticky
                      floating: true, // Allow AppBar to reappear on scroll up
                      leading: IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                        onPressed: () {
                          _logger.i(
                            "SearchScreen: Back button pressed. Popping route.",
                          ); // Navigation Log
                          Navigator.maybePop(
                            context,
                          ); // Use maybePop for safety
                        },
                        tooltip: 'رجوع',
                      ),
                      titleSpacing: 0, // Remove default title spacing
                      title: TextField(
                        controller: _searchController,
                        autofocus: widget.initialQuery.isEmpty,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن دواء...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ), // h-4 w-4
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
                                    },
                                    splashRadius: 18,
                                  )
                                  : null,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical:
                                10, // Keep specific for input field height
                          ), // py-2 equivalent
                        ),
                        style: theme.textTheme.bodyLarge,
                      ),
                      actions: [
                        // Updated Filter Button Style (Ghost)
                        TextButton(
                          onPressed: _openFilterDrawer,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                colorScheme.onSurfaceVariant, // Icon/Text color
                            shape:
                                const CircleBorder(), // Make it circular like IconButton
                            padding: const EdgeInsets.all(
                              AppSpacing.small, // Use constant (8px)
                            ), // Adjust padding
                            minimumSize:
                                Size.zero, // Remove minimum size constraint
                          ),
                          child: const Icon(
                            LucideIcons.filter,
                            size: 20,
                          ), // h-5 w-5
                        ),
                        AppSpacing.gapHSmall, // Use constant (8px)
                      ],
                      bottom: PreferredSize(
                        // Add bottom border
                        preferredSize: const Size.fromHeight(1.0),
                        child: Container(
                          color: colorScheme.outline,
                          height: 1.0,
                        ), // border-b border-border
                      ),
                    ),
                    _buildResultsListSliver(
                      context,
                      provider,
                    ), // Build results as sliver
                  ],
                ),
              ),
              const BannerAdWidget(), // Keep banner ad at the bottom
            ],
          ),
        ),
      );
    } catch (e, s) {
      // Catch and log any error during the build method
      _logger.e("SearchScreen: >>>>> CRITICAL ERROR DURING BUILD <<<<<", e, s);
      // Return a simple error widget instead of crashing
      return Scaffold(
        body: Center(
          child: Padding(
            padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
            child: Text(
              'Error building SearchScreen:\n$e\n\n$s', // Include stack trace
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textDirection: TextDirection.ltr, // Ensure LTR for error messages
            ),
          ),
        ),
      );
    } finally {
      _logger.i("SearchScreen: >>>>> build EXIT <<<<<"); // Log exit
    }
  }

  // Updated to return a Sliver instead of a Widget
  Widget _buildResultsListSliver(
    BuildContext context,
    MedicineProvider provider,
  ) {
    if (provider.isLoading && provider.filteredMedicines.isEmpty) {
      return const SliverFillRemaining(
        // Use SliverFillRemaining for center alignment
        child: Center(child: CircularProgressIndicator()),
        hasScrollBody: false,
      );
    } else if (provider.error.isNotEmpty &&
        provider.filteredMedicines.isEmpty) {
      return SliverFillRemaining(
        // Use SliverFillRemaining
        child: Center(
          child: Text(
            'خطأ: ${provider.error}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        hasScrollBody: false,
      );
    } else if (provider.filteredMedicines.isEmpty &&
        provider.searchQuery.isNotEmpty) {
      // Show empty state only if a search was performed and yielded no results
      return SliverFillRemaining(
        // Use SliverFillRemaining
        child: _buildEmptySearchMessage(context),
        hasScrollBody: false,
      );
    } else if (provider.filteredMedicines.isEmpty &&
        provider.searchQuery.isEmpty) {
      // Optionally show a prompt to start searching if the list is empty initially
      return SliverFillRemaining(
        // Use SliverFillRemaining
        child: Center(
          child: Text(
            'ابدأ البحث عن دواء...',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ),
        hasScrollBody: false,
      );
    }

    // Add loading indicator or end message at the bottom
    return SliverPadding(
      padding: AppSpacing.edgeInsetsAllLarge, // Use constant (16px)
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Existing drug card rendering
            if (index < provider.filteredMedicines.length) {
              final drug = provider.filteredMedicines[index];
              return Padding(
                padding: AppSpacing.edgeInsetsVMedium, // Use constant (12px)
                child: DrugCard(
                  drug: drug,
                  type: DrugCardType.detailed,
                  onTap: () => _navigateToDetails(context, drug),
                ),
              );
            }
            // Render loading indicator or end message
            else if (provider.isLoadingMore) {
              return Padding(
                // Use constant
                padding: AppSpacing.edgeInsetsVLarge, // Use constant (16px)
                child: const Center(child: CircularProgressIndicator()),
              );
            } else if (!provider.hasMoreItems) {
              return Padding(
                // Use constant
                padding: AppSpacing.edgeInsetsVLarge, // Use constant (16px)
                child: Center(
                  child: Text(
                    'وصلت إلى نهاية القائمة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink(); // Should not happen
            }
          },
          // Add 1 to child count if loading more or at the end
          childCount:
              provider.filteredMedicines.length +
              (provider.isLoadingMore || !provider.hasMoreItems ? 1 : 0),
        ),
      ),
    );
  }

  Widget _buildEmptySearchMessage(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          AppSpacing.xxlarge,
        ), // Corrected: Use constant value directly
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 48,
              color: theme.hintColor.withOpacity(0.7),
            ), // SearchIcon h-12 w-12 text-muted-foreground
            AppSpacing.gapVLarge, // Use constant (16px)
            Text(
              'لم يتم العثور على نتائج',
              style: theme.textTheme.titleLarge,
            ), // text-lg
            AppSpacing.gapVSmall, // Use constant (8px)
            Text(
              'حاول البحث بكلمات أخرى أو تحقق من الإملاء.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ), // text-muted-foreground
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
