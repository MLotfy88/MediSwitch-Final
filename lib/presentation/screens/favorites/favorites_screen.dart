import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/utils/drug_entity_converter.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/animation_helpers.dart';
import '../../widgets/home/drug_card.dart';
import '../details/drug_details_screen.dart';

/// Favorites Screen
/// Displays favorites from MedicineProvider
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header - Sticky with backdrop blur effect
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.heart,
                        color: colorScheme.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and count
                    Expanded(
                      child: Consumer<MedicineProvider>(
                        builder: (context, provider, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRTL ? 'المفضلة' : 'Favorites',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isRTL
                                    ? '${provider.favorites.length} أدوية محفوظة'
                                    : '${provider.favorites.length} saved drugs',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Favorites List
          Expanded(
            child: Consumer<MedicineProvider>(
              builder: (context, provider, child) {
                final favorites = provider.favorites;

                if (favorites.isEmpty) {
                  return _buildEmptyState(context, l10n, isRTL, colorScheme);
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final drug = favorites[index];
                    return FadeSlideAnimation(
                      delay: StaggeredAnimationHelper.delayFor(index),
                      child: DrugCard(
                        drug: drugEntityToUIModel(
                          drug,
                          isFavorite: true,
                          isPopularOverride: provider.isDrugPopular(drug.id),
                          isNewOverride: provider.isDrugNew(drug.id),
                        ),
                        onFavoriteToggle: (String drugId) {
                          // Since we pass the whole entity to DrugCard now,
                          // we should ideally pass a callback that takes ID for convenience
                          // or simple toggle. DrugCard logic handles the visual toggle via isFavorite param.
                          // But here we want to update provider.
                          provider.toggleFavorite(drug);
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder:
                                  (context) => DrugDetailsScreen(drug: drug),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    bool isRTL,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.heart,
                size: 40,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              isRTL ? 'لا توجد أدوية محفوظة' : 'No favorites yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              isRTL
                  ? 'اضغط على أيقونة القلب لحفظ الأدوية هنا'
                  : 'Tap the heart icon on any drug to save it here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
