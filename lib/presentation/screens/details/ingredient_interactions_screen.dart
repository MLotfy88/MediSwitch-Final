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
import 'package:mediswitch/presentation/widgets/modern_search_bar.dart';

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

  List<DrugInteraction> _allInteractions = []; // Full list for filtering
  List<DrugInteraction> _filteredInteractions = []; // Display list

  /// Whether data is currently being loaded
  bool _isLoading = true;

  /// Search query string
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInteractions();
  }

  /// Loads interaction data from repository
  Future<void> _loadInteractions() async {
    try {
      List<DrugInteraction> specificList = [];

      if (widget.ingredient != null) {
        if (!widget.onlyFood) {
          specificList = await _interactionRepository.getInteractionsWith(
            widget.ingredient!.name,
          );
        }

        // Fetch Food Interactions
        try {
          // Create a temporary drug entity with the active ingredient name to lookup food interactions
          final tempDrug = DrugEntity(
            id: null,
            tradeName: '',
            arabicName: '',
            price: '0',
            // oldPrice: null,
            mainCategory: '',
            active: widget.ingredient!.name,
            company: '',
            dosageForm: '',
            concentration: '',
            unit: '',
            usage: '',
            description: '',
            lastPriceUpdate: '',
            pharmacology: '',
          );

          final foodInteractions = await _interactionRepository
              .getFoodInteractions(tempDrug);

          // Convert strings to DrugInteraction objects
          for (final foodDesc in foodInteractions) {
            specificList.add(
              DrugInteraction(
                id: -1, // Dummy ID
                ingredient1: widget.ingredient!.name,
                ingredient2: 'Food / Diet',
                severity: 'Major', // Assume significant if listed
                effect: foodDesc,
                source: 'Database', // or 'Food'
                type: 'food',
              ),
            );
          }
        } catch (e) {
          debugPrint('Error loading food interactions: $e');
        }
      } else {
        specificList = await _interactionRepository.getHighRiskInteractions();
      }

      // usage of severityEnum
      specificList.sort(
        (a, b) => _compareSeverity(b.severityEnum, a.severityEnum),
      );

      if (mounted) {
        setState(() {
          _allInteractions = specificList;
          // Sort to put Food Interactions (Severity Major, ID -1) at TOP if we are in Ingredient mode?
          // Or just ensure they are visible. The separate list logic in build took care of display,
          // BUT `_buildInteractionsTab` in `DrugDetailsScreen` handles separate lists.
          // HERE in `IngredientInteractionsScreen` `build` method, we need to inspect `_allInteractions`.
          // The current `build` simply renders `_filteredInteractions`.
          // We need to make sure Food Interactions are NOT filtered out or buried.
          // They have `id: -1`.
          // We should perhaps keep them separate in the state?
          // Let's just create a separate list in state: `_foodInteractions`?
          // No, simpler: Just sort them to top.
          // Food interactions have 'Major' severity usually in my code.
          // Let's ensure they are added.
          _filteredInteractions = specificList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading interactions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _compareSeverity(InteractionSeverity a, InteractionSeverity b) {
    return _getSeverityWeight(a).compareTo(_getSeverityWeight(b));
  }

  int _getSeverityWeight(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.contraindicated:
        return 5;
      case InteractionSeverity.severe:
        return 4;
      case InteractionSeverity.major:
        return 3;
      case InteractionSeverity.moderate:
        return 2;
      case InteractionSeverity.minor:
        return 1;
      case InteractionSeverity.unknown:
        return 0;
    }
  }

  void _onSearch(String query) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredInteractions = List.from(_allInteractions);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredInteractions =
            _allInteractions.where((i) {
              final effect =
                  isRTL ? (i.arabicEffect ?? i.effect ?? '') : (i.effect ?? '');
              final otherIngredient =
                  i.ingredient1.toLowerCase() ==
                          widget.ingredient?.name.toLowerCase()
                      ? i.ingredient2
                      : i.ingredient1;

              return otherIngredient.toLowerCase().contains(lowerQuery) ||
                  effect.toLowerCase().contains(lowerQuery);
            }).toList();
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

          // Search Bar (Only if showing ALL interactions)
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
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final interaction = _filteredInteractions[index];
                  // Highlight Food Interactions
                  final isFood =
                      interaction.ingredient1 == 'Food / Diet' ||
                      interaction.ingredient2 == 'Food / Diet';
                  // Highlight Food Interactions
                  if (isFood) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0 ||
                              (_filteredInteractions[index - 1].ingredient1 !=
                                      'Food / Diet' &&
                                  _filteredInteractions[index - 1]
                                          .ingredient2 !=
                                      'Food / Diet'))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                isRTL ? 'تفاعلات الطعام' : 'Food Interactions',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          InteractionCard(
                            interaction: interaction,
                          ).animate().fadeIn(),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child:
                        InteractionCard(
                          interaction: interaction,
                        ).animate().fadeIn(delay: (20 * index).ms).slideX(),
                  );
                }, childCount: _filteredInteractions.length),
              ),
            ),
        ],
      ),
    );
  }
}
