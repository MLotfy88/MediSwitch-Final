import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/repositories/interaction_repository.dart';
import '../../core/di/locator.dart';
import 'drug_card.dart';

/// A widget that displays high-risk drugs in a horizontal list
class HighRiskDrugsCard extends StatelessWidget {
  const HighRiskDrugsCard({
    required this.allDrugs,
    required this.onDrugTap,
    super.key,
  });

  final List<DrugEntity> allDrugs;
  final void Function(DrugEntity) onDrugTap;

  @override
  Widget build(BuildContext context) {
    // 1. Filter drugs with interactions
    final interactionRepo = locator<InteractionRepository>();
    final highRiskDrugs =
        allDrugs
            .where((drug) => interactionRepo.hasKnownInteractions(drug))
            .take(10) // Increased limit to 10
            .toList();

    if (highRiskDrugs.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 2. Section Header (Custom with Warning Icon)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                size: 20,
                color: Colors.amber.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.highRiskDrugs,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              // Optional: "See All" button could go here
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Horizontal List of Cards
        SizedBox(
          height: 220, // Height for DrugCardType.thumbnail
          child: ListView.separated(
            itemCount: highRiskDrugs.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return DrugCard(
                drug: highRiskDrugs[index],
                onTap: () => onDrugTap(highRiskDrugs[index]),
                type: DrugCardType.thumbnail, // Use standard thumbnail card
                isPopular: false, // Don't show popular star here
                isAlternative: false,
              );
            },
          ),
        ),
      ],
    );
  }
}
