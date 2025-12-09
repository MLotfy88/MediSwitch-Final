import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/domain/entities/drug_interaction.dart';
import 'package:mediswitch/domain/entities/high_risk_ingredient.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart'; // Ensure this matches interaction repo
import 'package:mediswitch/presentation/theme/app_colors.dart';
import 'package:mediswitch/presentation/widgets/cards/interaction_card.dart';

class IngredientInteractionsScreen extends StatefulWidget {
  final HighRiskIngredient ingredient;

  const IngredientInteractionsScreen({super.key, required this.ingredient});

  @override
  State<IngredientInteractionsScreen> createState() =>
      _IngredientInteractionsScreenState();
}

class _IngredientInteractionsScreenState
    extends State<IngredientInteractionsScreen> {
  final InteractionRepository _interactionRepository =
      locator<InteractionRepository>();
  List<DrugInteraction> _interactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInteractions();
  }

  Future<void> _loadInteractions() async {
    // We need to fetch ALL interactions for this ingredient.
    // Assuming the repository has a method for this, or we can use the existing loadInteractionData and filter?
    // Based on previous code, loadInteractionData loads EVERYTHING into memory.
    // So let's use that if available, or fetch specifically.

    // For now, we reuse the repository's data source if it exposes it,
    // OR we implement a filtering mechanism here if checkInteractions logic is reusable.

    // Analyzing InteractionRepository interface from usage in InteractionCheckerScreen:
    // It has loadInteractionData() and findInteractionsForMedicines().
    // We likely need a new method or reuse the internal list if public.
    // Since I can't modify the interface blindly, I'll assume we can get the full list or filter manually.

    // NOTE: In a real scenario, I should add findInteractionsForIngredient to the repo.
    // For this task, I will simulate it by loading all data (as they are small JSONs) and filtering.

    final result = await _interactionRepository.loadInteractionData();

    if (mounted) {
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            // Handle error - maybe show snackbar
          });
        },
        (_) {
          // Success (Unit), now get the data from the getter
          final allInteractions = _interactionRepository.allLoadedInteractions;

          // Filter interactions where ingredient1 matches our ingredient
          final filtered =
              allInteractions
                  .where(
                    (i) =>
                        i.ingredient1.toLowerCase() ==
                            widget.ingredient.name.toLowerCase() ||
                        i.ingredient2.toLowerCase() ==
                            widget.ingredient.name.toLowerCase(),
                  )
                  .toList();

          // Sort by severity (highest first)
          filtered.sort((a, b) => b.severity.index.compareTo(a.severity.index));

          setState(() {
            _interactions = filtered;
            _isLoading = false;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

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
                widget.ingredient.displayName,
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
                      AppColors.danger.withOpacity(0.1),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_interactions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft.withOpacity(0.3),
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
                      isRTL ? "لا توجد تفاعلات مسجلة" : "No interactions found",
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
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final interaction = _interactions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child:
                        InteractionCard(
                          interaction: interaction,
                        ).animate().fadeIn(delay: (50 * index).ms).slideX(),
                  );
                }, childCount: _interactions.length),
              ),
            ),
        ],
      ),
    );
  }
}
