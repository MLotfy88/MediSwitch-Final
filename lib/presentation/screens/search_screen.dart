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

  @override
  void initState() {
    super.initState();
    _logger.i(
      "SearchScreen: initState called. Initial query: '${widget.initialQuery}'",
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
  }

  @override
  void dispose() {
    _logger.i("SearchScreen: dispose called.");
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final query = _searchController.text;
        _logger.i(
          "SearchScreen: Debounced search triggered with query: '$query'",
        );
        context.read<MedicineProvider>().setSearchQuery(query);
      }
    });
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
    _logger.d("SearchScreen: Building widget.");
    final provider = context.watch<MedicineProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                slivers: <Widget>[
                  SliverAppBar(
                    backgroundColor: colorScheme.surface, // bg-card
                    foregroundColor:
                        colorScheme.onSurfaceVariant, // text-muted-foreground
                    elevation: 0, // Remove shadow
                    pinned: true, // Make AppBar sticky
                    floating: true, // Allow AppBar to reappear on scroll up
                    leading: IconButton(
                      icon: Icon(LucideIcons.arrowLeft, size: 20), // h-5 w-5
                      onPressed: () => Navigator.of(context).pop(),
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
                          vertical: 10,
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
                          padding: const EdgeInsets.all(8.0), // Adjust padding
                          minimumSize:
                              Size.zero, // Remove minimum size constraint
                        ),
                        child: Icon(LucideIcons.filter, size: 20), // h-5 w-5
                      ),
                      const SizedBox(width: 8), // Add some padding
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

    // Use SliverPadding + SliverList for better spacing control (gap-3)
    return SliverPadding(
      padding: const EdgeInsets.all(16.0), // p-4 for the list container
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final drug = provider.filteredMedicines[index];
          return Padding(
            // Add padding between items (gap-3 equivalent)
            padding: const EdgeInsets.only(bottom: 12.0),
            child: DrugCard(
              drug: drug,
              type:
                  DrugCardType.detailed, // Use detailed card for search results
              onTap: () => _navigateToDetails(context, drug),
            ),
          );
        }, childCount: provider.filteredMedicines.length),
      ),
    );
  }

  Widget _buildEmptySearchMessage(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.searchX,
              size: 48,
              color: theme.hintColor.withOpacity(0.7),
            ), // SearchIcon h-12 w-12 text-muted-foreground
            const SizedBox(height: 16),
            Text(
              'لم يتم العثور على نتائج',
              style: theme.textTheme.titleLarge,
            ), // text-lg
            const SizedBox(height: 8),
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
