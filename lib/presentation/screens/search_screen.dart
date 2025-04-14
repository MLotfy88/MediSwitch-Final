import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/locator.dart'; // Import locator
import '../../core/services/file_logger_service.dart'; // Import logger
import '../bloc/medicine_provider.dart';
import '../widgets/drug_card.dart';
import 'drug_details_screen.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../../domain/entities/drug_entity.dart'; // Import DrugEntity
import 'package:flutter_animate/flutter_animate.dart'; // Import flutter_animate
import '../services/ad_service.dart'; // Import AdService

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  final FileLoggerService _logger = locator<FileLoggerService>();
  final AdService _adService =
      locator<AdService>(); // Define AdService instance

  @override
  void initState() {
    super.initState();
    _logger.i(
      "SearchScreen: initState called. Initial query: '${widget.initialQuery}'",
    );
    _searchController = TextEditingController(text: widget.initialQuery ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.initialQuery != null) {
        _logger.d(
          "SearchScreen: Triggering initial search from initState for query: '${widget.initialQuery!}'",
        );
        context.read<MedicineProvider>().setSearchQuery(widget.initialQuery!);
      } else if (mounted && widget.initialQuery == null) {
        _logger.d(
          "SearchScreen: No initial query, clearing previous search state.",
        );
        context.read<MedicineProvider>().setSearchQuery('');
      }
    });
  }

  @override
  void dispose() {
    _logger.i("SearchScreen: dispose called.");
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _logger.d(
          "SearchScreen: Debounced search triggered for query: '$query'",
        );
        context.read<MedicineProvider>().setSearchQuery(query);
      }
    });
  }

  void _clearSearch() {
    _logger.i("SearchScreen: Clear search called.");
    _searchController.clear();
    if (mounted) {
      context.read<MedicineProvider>().setSearchQuery('');
    }
  }

  void _openFilterModal() {
    _logger.i("SearchScreen: Open filter modal called.");
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ChangeNotifierProvider.value(
            value: context.read<MedicineProvider>(),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24.0),
                    ),
                  ),
                  child: FilterBottomSheet(scrollController: scrollController),
                );
              },
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.i("SearchScreen: Building widget...");
    final medicineProvider = context.watch<MedicineProvider>();
    final medicines = medicineProvider.filteredMedicines;
    final isLoading = medicineProvider.isLoading;
    final isLoadingMore = medicineProvider.isLoadingMore;
    final error = medicineProvider.error;
    final hasMoreItems = medicineProvider.hasMoreItems;
    _logger.d(
      "SearchScreen: State - isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: '$error', medicines: ${medicines.length}, hasMore: $hasMoreItems",
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: widget.initialQuery == null,
            decoration: InputDecoration(
              hintText: 'ابحث عن دواء...',
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).hintColor,
              ),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        color: Theme.of(context).hintColor,
                        onPressed: _clearSearch,
                      )
                      : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            onChanged: _onSearchChanged,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'تصفية النتائج',
            onPressed: _openFilterModal,
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          // Display Loading/Error/Results
          if (isLoading && medicines.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (error.isNotEmpty)
            Expanded(child: _buildErrorWidget(context, error))
          else if (medicines.isEmpty && _searchController.text.isNotEmpty)
            const Expanded(
              child: Center(child: Text('لا توجد نتائج مطابقة لبحثك.')),
            )
          else if (medicines.isEmpty && _searchController.text.isEmpty)
            const Expanded(
              child: Center(child: Text('ابدأ البحث أو اختر فئة...')),
            )
          else
            Expanded(
              child: LayoutBuilder(
                // Keep LayoutBuilder for potential future grid use
                builder: (context, constraints) {
                  // Always use ListView for now
                  return ListView.builder(
                    // controller: _scrollController, // Add controller if pagination needed here
                    padding: const EdgeInsets.all(8.0),
                    itemCount:
                        medicines.length +
                        (isLoadingMore ? 1 : 0) +
                        (!hasMoreItems && medicines.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < medicines.length) {
                        final drug = medicines[index];
                        // Always use detailed card in search results for now
                        Widget card = DrugCard(
                          drug: drug,
                          type: DrugCardType.detailed, // Use detailed always
                          onTap: () => _navigateToDetails(context, drug),
                        );
                        // Apply animation
                        card = card.animate().fadeIn(
                          delay: (index % 10 * 50).ms,
                        );
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: card,
                        );
                      } else if (isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (!hasMoreItems) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Center(
                            child: Text(
                              'نهاية النتائج',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Container(); // Should not happen
                      }
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
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

  Widget _buildErrorWidget(BuildContext context, String error) {
    _logger.w("SearchScreen: Building error widget: $error");
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              error,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: () {
                _logger.i("SearchScreen: Retry button pressed.");
                // Retry the current search/filter
                context.read<MedicineProvider>().setSearchQuery(
                  _searchController.text,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
