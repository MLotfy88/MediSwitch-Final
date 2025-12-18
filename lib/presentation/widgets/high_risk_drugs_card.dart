import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/di/locator.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/interaction_severity.dart';
import '../../domain/repositories/interaction_repository.dart';
import 'dangerous_drug_card.dart';

/// A widget that displays high-risk drugs in a horizontal list
class HighRiskDrugsCard extends StatefulWidget {
  const HighRiskDrugsCard({
    required this.allDrugs,
    required this.onDrugTap,
    super.key,
  });

  final List<DrugEntity> allDrugs;
  final void Function(DrugEntity) onDrugTap;

  @override
  State<HighRiskDrugsCard> createState() => _HighRiskDrugsCardState();
}

class _HighRiskDrugItem {
  final DrugEntity drug;
  final int count;
  final InteractionSeverity severity;

  _HighRiskDrugItem(this.drug, this.count, this.severity);
}

class _HighRiskDrugsCardState extends State<HighRiskDrugsCard> {
  final List<_HighRiskDrugItem> _highRiskDrugs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHighRiskDrugs();
  }

  @override
  void didUpdateWidget(covariant HighRiskDrugsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allDrugs != widget.allDrugs) {
      _loadHighRiskDrugs();
    }
  }

  Future<void> _loadHighRiskDrugs() async {
    if (!mounted) return;

    // Reset state if reloading
    setState(() {
      _isLoading = true;
      _highRiskDrugs.clear();
    });

    final repo = locator<InteractionRepository>();
    final results = <_HighRiskDrugItem>[];

    // Optimize: limit checking to first 50 drugs to prevent UI freeze
    // if a very large list is passed.
    final candidateDrugs = widget.allDrugs.take(50).toList();

    for (final drug in candidateDrugs) {
      if (results.length >= 10) break; // Limit to 10 high risk items

      // Check if it has interactions (async)
      final hasInteractions = await repo.hasKnownInteractions(drug);
      if (hasInteractions) {
        // Fetch details
        final count = await repo.getInteractionCountForDrug(drug);
        final severity = await repo.getMaxSeverityForDrug(drug);

        results.add(_HighRiskDrugItem(drug, count, severity));
      }
    }

    if (mounted) {
      setState(() {
        _highRiskDrugs.addAll(results);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show nothing or skeleton while loading to avoid layout jump?
      // For now, shrinking to avoid blank space if no risks found.
      return const SizedBox.shrink();
    }

    if (_highRiskDrugs.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
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
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Horizontal List
        SizedBox(
          height: 190,
          child: ListView.separated(
            itemCount: _highRiskDrugs.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _highRiskDrugs[index];

              return DangerousDrugCard(
                drug: item.drug,
                onTap: () => widget.onDrugTap(item.drug),
                interactionCount: item.count,
                severity: item.severity,
              );
            },
          ),
        ),
      ],
    );
  }
}
