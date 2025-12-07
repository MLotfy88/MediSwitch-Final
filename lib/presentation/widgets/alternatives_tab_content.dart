import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import 'package:lucide_icons/lucide_icons.dart'; // Import LucideIcons

import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/repositories/drug_repository.dart'; // Import DrugRepository
import '../screens/details/drug_details_screen.dart'; // Import DrugDetailsScreen
import 'drug_card.dart';

class AlternativesTabContent extends StatefulWidget {
  final DrugEntity originalDrug;

  const AlternativesTabContent({super.key, required this.originalDrug});

  @override
  State<AlternativesTabContent> createState() => _AlternativesTabContentState();
}

class _AlternativesTabContentState extends State<AlternativesTabContent> {
  final FileLoggerService _logger = locator<FileLoggerService>();
  final DrugRepository _drugRepository =
      locator<DrugRepository>(); // Inject DrugRepository

  List<DrugEntity> _similars = [];
  List<DrugEntity> _alternatives = [];
  bool _isLoadingSimilars = true;
  bool _isLoadingAlternatives = true;
  String? _similarsError;
  String? _alternativesError;

  @override
  void initState() {
    super.initState();
    _logger.d(
      "AlternativesTabContent: initState for drug: ${widget.originalDrug.tradeName}",
    );
    _fetchSimilarsAndAlternatives();
  }

  Future<void> _fetchSimilarsAndAlternatives() async {
    // Reset state
    setState(() {
      _isLoadingSimilars = true;
      _isLoadingAlternatives = true;
      _similarsError = null;
      _alternativesError = null;
      _similars = [];
      _alternatives = [];
    });

    // Fetch Similars
    _logger.i("Fetching similars for ${widget.originalDrug.tradeName}");
    final similarsResult = await _drugRepository.findSimilars(
      widget.originalDrug,
    );
    if (mounted) {
      similarsResult.fold(
        (failure) {
          _logger.e("Error fetching similars: ${failure.message}");
          setState(() {
            _similarsError = failure.message;
            _isLoadingSimilars = false;
          });
        },
        (similars) {
          _logger.i("Found ${similars.length} similars.");
          setState(() {
            _similars = similars;
            _isLoadingSimilars = false;
          });
        },
      );
    }

    // Fetch Alternatives
    _logger.i("Fetching alternatives for ${widget.originalDrug.tradeName}");
    final alternativesResult = await _drugRepository.findAlternatives(
      widget.originalDrug,
    );
    if (mounted) {
      alternativesResult.fold(
        (failure) {
          _logger.e("Error fetching alternatives: ${failure.message}");
          setState(() {
            _alternativesError = failure.message;
            _isLoadingAlternatives = false;
          });
        },
        (alternatives) {
          _logger.i("Found ${alternatives.length} alternatives.");
          setState(() {
            _alternatives = alternatives;
            _isLoadingAlternatives = false;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d(
      "AlternativesTabContent: Building widget for drug: ${widget.originalDrug.tradeName}",
    );
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    bool isLoading = _isLoadingSimilars || _isLoadingAlternatives;
    String combinedError = '';
    if (_similarsError != null) {
      combinedError += "${l10n.errorFetchingInteractions}: $_similarsError\n";
    }
    if (_alternativesError != null) {
      combinedError += "${l10n.errorFetchingInteractions}: $_alternativesError";
    }
    bool hasError = combinedError.isNotEmpty;
    bool noResults =
        !isLoading && !hasError && _similars.isEmpty && _alternatives.isEmpty;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            combinedError.trim(),
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (noResults) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.search,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noSimilarsFound, // Fallback message
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      key: PageStorageKey<String>(
        'alternatives_${widget.originalDrug.tradeName}',
      ), // Use tradeName instead of ID
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // --- Similars Header ---
              _buildSectionHeader(context, l10n.similarsTitle),
              const SizedBox(height: 8),
              if (_similars.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      l10n.noSimilarsFound,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),

        // --- Similars List (Virtualized) ---
        if (_similars.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final drug = _similars[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0), // Spacing
                  child: DrugCard(
                    drug: drug,
                    type: DrugCardType.detailed,
                    isAlternative: false,
                    onTap: () => _onDrugTap(context, drug),
                  ),
                );
              }, childCount: _similars.length),
            ),
          ),

        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12), // Space between sections
              // --- Alternatives Header ---
              _buildSectionHeader(context, l10n.alternativesTitle),
              const SizedBox(height: 8),
              if (_alternatives.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      l10n.noAlternativesFoundMsg,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),

        // --- Alternatives List (Virtualized) ---
        if (_alternatives.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final drug = _alternatives[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0), // Spacing
                  child: DrugCard(
                    drug: drug,
                    type: DrugCardType.detailed,
                    isAlternative: true,
                    onTap: () => _onDrugTap(context, drug),
                  ),
                );
              }, childCount: _alternatives.length),
            ),
          ),

        // Bottom Padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }

  // Helper to build section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  void _onDrugTap(BuildContext context, DrugEntity drug) {
    _logger.i("AlternativesTabContent: Tapped drug: ${drug.tradeName}");
    // Use pushReplacement to avoid deep stack, or just push for normal nav
    // If we want to replace the current detail page (since we are already in one), pushReplacement is good.
    // However, user might want to go back. Let's use push for now as per stack behavior, but previous code used pushReplacement.
    // I'll stick to pushReplacement if that was the intent.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (context) => DrugDetailsScreen(drug: drug),
      ), // Fix generics
    );
  }
}
