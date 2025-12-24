import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/presentation/widgets/cards/dangerous_drug_card.dart';
import 'package:provider/provider.dart';

import 'details/ingredient_interactions_screen.dart';

class FoodInteractionsListScreen extends StatelessWidget {
  const FoodInteractionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.foodInteractionsTitle),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, _) {
          final ingredients = provider.foodInteractionIngredients;

          if (ingredients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.apple,
                    size: 48,
                    color: theme.appColors.mutedForeground,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isRTL ? 'لا توجد بيانات' : 'No data available',
                    style: TextStyle(color: theme.appColors.mutedForeground),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ingredients.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ingredient = ingredients[index];
              final card = DangerousDrugCard(
                title: ingredient.displayName,
                subtitle: "Interacts w/ Food",
                riskLevel: RiskLevel.high,
                interactionCount: 1, // Generic
                onTap: () {
                  // Navigate to Search Screen filtering by this ingredient
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder:
                          (_) => IngredientInteractionsScreen(
                            ingredient: ingredient,
                            onlyFood: true,
                          ),
                    ),
                  );
                },
              );

              return card.animate().fadeIn(delay: (30 * index).ms).slideX();
            },
          );
        },
      ),
    );
  }
}
