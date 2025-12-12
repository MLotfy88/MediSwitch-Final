import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/high_risk_ingredient.dart';
import 'package:mediswitch/domain/entities/interaction_severity.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart'; // Ensure this matches interaction repo
import 'package:mediswitch/presentation/theme/app_colors.dart';
import 'package:mediswitch/presentation/widgets/cards/interaction_card.dart';
import 'package:mediswitch/presentation/widgets/modern_search_bar.dart';

class IngredientInteractionsScreen extends StatefulWidget {
  /// The ingredient to filter by. If null, shows all high-risk interactions.
  final HighRiskIngredient? ingredient;

  /// Creates a screen to display drug interactions.
  const IngredientInteractionsScreen({super.key, this.ingredient});

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

  /// Loads interaction data from repository and filters based on widget.ingredient
  Future<void> _loadInteractions() async {
    final result = await _interactionRepository.loadInteractionData();

    if (mounted) {
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
          });
        },
        (_) {
          final allLoaded = _interactionRepository.allLoadedInteractions;
          List<DrugInteraction> specificList;

          if (widget.ingredient != null) {
            // Filter specific ingredient
            specificList =
                allLoaded
                    .where(
                      (i) =>
                          i.ingredient1.toLowerCase() ==
                              widget.ingredient!.name.toLowerCase() ||
                          i.ingredient2.toLowerCase() ==
                              widget.ingredient!.name.toLowerCase(),
                    )
                    .toList();
          } else {
            // Get ALL High Risk (Major/Severe/Contraindicated)
            specificList =
                allLoaded.where((i) {
                  return i.severity == InteractionSeverity.contraindicated ||
                      i.severity == InteractionSeverity.severe ||
                      i.severity == InteractionSeverity.major;
                }).toList();
          }

          // Initial Sort by severity (highest first)
          specificList.sort(
            (a, b) => b.severity.index.compareTo(a.severity.index),
          );

          setState(() {
            _allInteractions = specificList;
            _filteredInteractions = specificList;
            _isLoading = false;
          });
        },
      );
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredInteractions = List.from(_allInteractions);
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredInteractions =
            _allInteractions.where((i) {
              return i.ingredient1.toLowerCase().contains(lowerQuery) ||
                  i.ingredient2.toLowerCase().contains(lowerQuery) ||
                  i.effect.toLowerCase().contains(lowerQuery) ||
                  i.arabicEffect.contains(query) ||
                  i.recommendation.toLowerCase().contains(lowerQuery) ||
                  i.arabicRecommendation.contains(query);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final title =
        widget.ingredient?.displayName ??
        (isRTL ? 'التفاعلات الخطيرة' : 'High Risk Interactions');

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
