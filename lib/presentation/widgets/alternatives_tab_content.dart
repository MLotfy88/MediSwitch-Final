import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // No longer using Provider here
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import generated localizations
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/repositories/drug_repository.dart'; // Import DrugRepository
// import '../bloc/alternatives_provider.dart'; // No longer using AlternativesProvider
import 'drug_card.dart';
import '../screens/drug_details_screen.dart'; // Import DrugDetailsScreen
// import '../widgets/custom_badge.dart'; // No longer needed here

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
    // final provider = context.watch<AlternativesProvider>(); // Removed provider
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!; // Get localizations

    bool isLoading = _isLoadingSimilars || _isLoadingAlternatives;
    // Combine error messages for display
    String combinedError = '';
    if (_similarsError != null) {
      combinedError +=
          "${l10n.errorFetchingInteractions}: $_similarsError\n"; // Re-use interaction error key for now
    }
    if (_alternativesError != null) {
      combinedError +=
          "${l10n.errorFetchingInteractions}: $_alternativesError"; // Re-use interaction error key for now
    }
    bool hasError = combinedError.isNotEmpty;
    bool noResults =
        !isLoading && !hasError && _similars.isEmpty && _alternatives.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (hasError)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Text(
                combinedError.trim(), // Display combined errors
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (noResults)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            // If both are empty, show a combined message or specific ones?
            // Let's show specific messages within their sections instead.
            // child: Center(child: Text(l10n.noSimilarsFound)), // Or a more general message
            child: Container(), // Handled within sections now
          )
        else ...[
          // --- Similars Section ---
          _buildSectionHeader(
            context,
            l10n.similarsTitle,
          ), // Use localized string
          const SizedBox(height: 8),
          if (_isLoadingSimilars)
            const Center(
              child: CircularProgressIndicator(),
            ) // Should not happen if !isLoading overall
          else if (_similarsError != null)
            Center(
              child: Text(
                "${l10n.errorFetchingInteractions}: $_similarsError",
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ) // Show specific error
          else if (_similars.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(l10n.noSimilarsFound),
              ),
            ) // Use localized string for no similars
          else
            _buildDrugList(_similars, isAlternative: false),
          const SizedBox(height: 24), // Space between sections
          // --- Alternatives Section ---
          _buildSectionHeader(
            context,
            l10n.alternativesTitle,
          ), // Use localized string
          const SizedBox(height: 8),
          if (_isLoadingAlternatives)
            const Center(
              child: CircularProgressIndicator(),
            ) // Should not happen if !isLoading overall
          else if (_alternativesError != null)
            Center(
              child: Text(
                "${l10n.errorFetchingInteractions}: $_alternativesError",
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ) // Show specific error
          else if (_alternatives.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(l10n.noAlternativesFoundMsg),
              ),
            ) // Use localized string for no alternatives
          else
            _buildDrugList(_alternatives, isAlternative: true),
        ],
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

  // Helper to build the list of drugs (Similars or Alternatives)
  Widget _buildDrugList(List<DrugEntity> drugs, {required bool isAlternative}) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: drugs.length,
      itemBuilder: (context, index) {
        final drug = drugs[index];
        return DrugCard(
          drug: drug,
          type: DrugCardType.detailed,
          isAlternative:
              isAlternative, // Pass whether it's an alternative or similar
          onTap: () {
            _logger.i(
              "AlternativesTabContent: Tapped ${isAlternative ? 'alternative' : 'similar'}: ${drug.tradeName}",
            );
            Navigator.pushReplacement(
              // Use pushReplacement to avoid deep navigation stack
              context,
              MaterialPageRoute(
                builder: (context) => DrugDetailsScreen(drug: drug),
              ),
            );
          },
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12),
    );
  }
}
