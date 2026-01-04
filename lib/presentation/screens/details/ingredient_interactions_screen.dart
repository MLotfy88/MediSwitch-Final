import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/high_risk_ingredient.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';
import 'package:mediswitch/presentation/widgets/cards/interaction_card.dart';
import 'package:mediswitch/presentation/widgets/interaction_bottom_sheet.dart';
import 'package:mediswitch/presentation/widgets/modern_search_bar.dart';

/// A screen that displays interactions for a specific ingredient or drug.
class IngredientInteractionsScreen extends StatefulWidget {
  /// The ingredient to filter by. If null, shows all high-risk interactions.
  final HighRiskIngredient? ingredient;

  /// Whether to show only food interactions.
  final bool onlyFood;

  /// Creates a screen to display drug interactions.
  const IngredientInteractionsScreen({
    super.key,
    this.ingredient,
    this.onlyFood = false,
  });

  @override
  State<IngredientInteractionsScreen> createState() =>
      _IngredientInteractionsScreenState();
}

class _IngredientInteractionsScreenState
    extends State<IngredientInteractionsScreen> {
  final InteractionRepository _interactionRepository =
      locator<InteractionRepository>();
  final ScrollController _scrollController = ScrollController();

  List<DrugInteraction> _allInteractions =
      []; // Full list for filtering (Specific mode)
  List<DrugInteraction> _filteredInteractions = []; // Display list
  List<DrugInteraction> _paginatedInteractions = []; // List for See All mode

  /// Whether data is currently being loaded
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  static const int _pageSize = 20;

  /// Search query string
  String _searchQuery = '';

  // Debounce search
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInteractions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isSeeAllMode() &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  bool _isSeeAllMode() => widget.ingredient == null;

  /// Loads interaction data from repository
  Future<void> _loadInteractions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentOffset = 0;
        _hasMore = true;
        _paginatedInteractions = [];
        _filteredInteractions = []; // Clear display
      });
    }

    try {
      if (_isSeeAllMode()) {
        // --- SEE ALL HIGH RISK (Paginated) ---
        final newInteractions = await _interactionRepository
            .getHighRiskInteractions(
              limit: _pageSize,
              offset: _currentOffset,
              searchQuery: _searchQuery,
            );

        if (mounted) {
          setState(() {
            if (newInteractions.length < _pageSize) {
              _hasMore = false;
            }
            _paginatedInteractions.addAll(newInteractions);
            _filteredInteractions = _paginatedInteractions; // Direct mapping
            _currentOffset += newInteractions.length;
            _isLoading = false;
          });
        }
      } else {
        // --- SPECIFIC INGREDIENT (Legacy / Full Load) ---
        List<DrugInteraction> specificList = [];

        if (widget.onlyFood) {
          // Food Logic (Same as before)
          try {
            final tempDrug = DrugEntity(
              id: null,
              tradeName: widget.ingredient!.name,
              arabicName: '',
              price: '0',
              active: widget.ingredient!.name, // Fallback active = name
              company: '',
              dosageForm: '',
              concentration: '',
              unit: '',
              usage: '',
              lastPriceUpdate: '',
              pharmacology: '',
            );
            final foodInteractions = await _interactionRepository
                .getFoodInteractions(tempDrug);
            for (final foodDesc in foodInteractions) {
              specificList.add(
                DrugInteraction(
                  id: -1,
                  ingredient1: widget.ingredient!.name,
                  ingredient2: 'Food / Diet',
                  severity: 'Major',
                  effect: foodDesc,
                  source: 'Database',
                  type: 'food',
                ),
              );
            }
          } catch (e) {
            debugPrint('Error loading food: $e');
          }
        } else {
          // Ingredient Logic
          final searchTerm =
              widget.ingredient!.normalizedName ?? widget.ingredient!.name;
          specificList = await _interactionRepository.getInteractionsWith(
            searchTerm,
          );
        }

        // Sort locally
        specificList.sort(
          (a, b) => b.severityEnum.priority.compareTo(a.severityEnum.priority),
        );

        if (mounted) {
          setState(() {
            _allInteractions = specificList;
            _filteredInteractions = specificList; // Initial full list
            _isLoading = false;
          });
          // Apply local filter if search query exists (restoring state)
          if (_searchQuery.isNotEmpty) _filterLocalList(_searchQuery);
        }
      }
    } on Exception catch (e) {
      debugPrint('Error loading interactions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (!_isSeeAllMode()) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newInteractions = await _interactionRepository
          .getHighRiskInteractions(
            limit: _pageSize,
            offset: _currentOffset,
            searchQuery: _searchQuery,
          );

      if (mounted) {
        setState(() {
          if (newInteractions.length < _pageSize) {
            _hasMore = false;
          }
          _paginatedInteractions.addAll(newInteractions);
          _filteredInteractions = _paginatedInteractions;
          _currentOffset += newInteractions.length;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // Local filtering for Specific Ingredient Mode
  void _filterLocalList(String query) {
    if (_isSeeAllMode()) return; // Should not happen

    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final lowerQuery = query.toLowerCase();

    final filtered =
        _allInteractions.where((i) {
          final effect =
              isRTL ? (i.arabicEffect ?? i.effect ?? '') : (i.effect ?? '');
          // Use normalizedName for comparison if available
          final searchKey =
              widget.ingredient?.normalizedName?.toLowerCase() ??
              widget.ingredient?.name.toLowerCase();

          final String otherIngredient;
          if (searchKey != null) {
            otherIngredient =
                i.ingredient1.toLowerCase() == searchKey
                    ? i.ingredient2
                    : i.ingredient1;
          } else {
            otherIngredient = "${i.ingredient1} ${i.ingredient2}";
          }

          final isFoodInteraction = i.type == 'food';

          return otherIngredient.toLowerCase().contains(lowerQuery) ||
              effect.toLowerCase().contains(lowerQuery) ||
              (isFoodInteraction &&
                  (isRTL ? 'طعام' : 'food').toLowerCase().contains(lowerQuery));
        }).toList();

    setState(() {
      _filteredInteractions = filtered;
    });
  }

  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery == query) return;

      setState(() {
        _searchQuery = query;
      });

      if (_isSeeAllMode()) {
        _loadInteractions(reset: true); // Server-side search
      } else {
        if (query.isEmpty) {
          setState(() => _filteredInteractions = _allInteractions);
        } else {
          _filterLocalList(query);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final title =
        widget.onlyFood
            ? (isRTL ? 'تفاعلات الطعام' : 'Food Interactions')
            : (widget.ingredient?.displayName ??
                (isRTL ? 'التفاعلات الخطيرة' : 'High Risk Interactions'));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            leading: IconButton(
              icon: Icon(
                isRTL ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              centerTitle: true,
              title: Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.danger.withValues(alpha: 0.1),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ModernSearchBar(
                hintText:
                    isRTL ? 'ابحث عن مادة فعالة...' : 'Search ingredient...',
                onChanged: _onSearch,
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredInteractions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.checkCircle,
                        size: 48,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isRTL
                          ? (_searchQuery.isNotEmpty
                              ? 'لا توجد نتائج'
                              : 'لا توجد تفاعلات مسجلة')
                          : (_searchQuery.isNotEmpty
                              ? 'No results found'
                              : 'No interactions found'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            if (_isSeeAllMode()) ...[
              // --- SEE ALL MODE (Infinite Scroll) ---
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final interaction = _filteredInteractions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child:
                          InteractionCard(
                            interaction: interaction,
                            showDetails: false,
                            onTap: () => _showInteractionDetails(interaction),
                          ).animate().fadeIn(),
                    );
                  }, childCount: _filteredInteractions.length),
                ),
              ),
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ] else ...[
              // --- SPECIFIC INGREDIENT MODE (Grouped) ---
              if (_filteredInteractions.any((i) => i.isPrimaryIngredient))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final primaryList =
                            _filteredInteractions
                                .where((i) => i.isPrimaryIngredient)
                                .toList();
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _InteractionSectionHeader(
                              title:
                                  isRTL
                                      ? 'تفاعلات مباشرة'
                                      : 'Direct Interactions',
                              subtitle:
                                  isRTL
                                      ? '${widget.ingredient?.name ?? 'المادة'} كمكون أساسي'
                                      : '${widget.ingredient?.name ?? 'Ingredient'} as primary component',
                              icon: LucideIcons.alertTriangle,
                              color: AppColors.danger,
                            ),
                          );
                        }
                        final interaction = primaryList[index - 1];
                        return PaginationWrapper(
                          key: ValueKey('primary_${interaction.id}_$index'),
                          index: index - 1,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InteractionCard(
                              interaction: interaction,
                              showDetails: false,
                              onTap: () => _showInteractionDetails(interaction),
                            ),
                          ),
                        );
                      },
                      childCount:
                          _filteredInteractions
                              .where((i) => i.isPrimaryIngredient)
                              .length +
                          1,
                    ),
                  ),
                ),
              if (_filteredInteractions.any((i) => !i.isPrimaryIngredient))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final secondaryList =
                            _filteredInteractions
                                .where((i) => !i.isPrimaryIngredient)
                                .toList();

                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoBanner(
                                  text:
                                      isRTL
                                          ? 'التفاعلات التالية تحدث عند وجود ${widget.ingredient?.name} كمكون ثانوي أو ضمن تركيبة دوائية، وقد تكون أقل خطورة أو تعتمد على الكمية.'
                                          : 'These interactions occur when ${widget.ingredient?.name} is present as a secondary component. They might be less critical or dose-dependent.',
                                  color: AppColors.info,
                                ),
                                const SizedBox(height: 16),
                                _InteractionSectionHeader(
                                  title:
                                      isRTL
                                          ? 'تفاعلات ثانوية'
                                          : 'Secondary Interactions',
                                  subtitle:
                                      isRTL
                                          ? 'أدوية تحتوي على ${widget.ingredient?.name}'
                                          : 'Drugs containing ${widget.ingredient?.name}',
                                  icon: LucideIcons.info,
                                  color: AppColors.info,
                                ),
                              ],
                            ),
                          );
                        }
                        final interaction = secondaryList[index - 1];
                        return PaginationWrapper(
                          key: ValueKey('secondary_${interaction.id}_$index'),
                          index: index - 1,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InteractionCard(
                              interaction: interaction,
                              showDetails: false,
                              onTap: () => _showInteractionDetails(interaction),
                            ),
                          ),
                        );
                      },
                      childCount:
                          _filteredInteractions
                              .where((i) => !i.isPrimaryIngredient)
                              .length +
                          1,
                    ),
                  ),
                ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 50)),
          ],
        ],
      ),
    );
  }

  void _showInteractionDetails(DrugInteraction interaction) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InteractionBottomSheet(interaction: interaction),
    );
  }
}

class _InteractionSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  const _InteractionSectionHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? theme.colorScheme.primary).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color ?? theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final Color color;

  const _InfoBanner({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class PaginationWrapper extends StatelessWidget {
  final Widget child;
  final int index;

  const PaginationWrapper({
    super.key,
    required this.child,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: (20 * (index % 10)).ms) // Limit delay for long lists
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }
}
