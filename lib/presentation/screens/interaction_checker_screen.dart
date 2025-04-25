import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // If using Provider for state management

import '../../core/di/locator.dart'; // For accessing InteractionRepository
import '../../domain/entities/drug_entity.dart';
import '../../domain/entities/drug_interaction.dart';
import '../../domain/repositories/interaction_repository.dart';
import '../../domain/repositories/drug_repository.dart'; // Import DrugRepository
// Removed import for custom_searchable_dropdown
import '../widgets/drug_search_delegate.dart'; // Import DrugSearchDelegate
import '../widgets/interaction_card.dart';
import '../bloc/medicine_provider.dart'; // Assuming this provides the list of all drugs for selection

// TODO: Implement localization using AppLocalizations

class InteractionCheckerScreen extends StatefulWidget {
  const InteractionCheckerScreen({super.key});

  @override
  State<InteractionCheckerScreen> createState() =>
      _InteractionCheckerScreenState();
}

class _InteractionCheckerScreenState extends State<InteractionCheckerScreen> {
  final InteractionRepository _interactionRepository =
      locator<InteractionRepository>();

  DrugEntity? _selectedDrug1;
  DrugEntity? _selectedDrug2;
  List<DrugInteraction> _interactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Fetch all drugs for the dropdowns/search delegates
  // This might be better handled in a dedicated provider/bloc
  List<DrugEntity> _allDrugs = [];

  @override
  void initState() {
    super.initState();
    // Load all drugs for selection - assuming MedicineProvider handles this
    // It's crucial that interaction data is loaded before this screen is used.
    // Consider triggering loadInteractionData earlier in the app lifecycle (e.g., InitializationScreen)
    _loadAllDrugs();
    _ensureInteractionDataLoaded();
  }

  Future<void> _loadAllDrugs() async {
    // Use DrugRepository to load all drugs
    print("InteractionCheckerScreen: Loading all drugs...");
    try {
      // Assuming DrugRepository is registered in locator
      final drugRepo = locator<DrugRepository>();
      // Assuming DrugRepository has a method like getAllDrugs()
      // Adjust the method name if it's different (e.g., fetchAllDrugs)
      final result =
          await drugRepo.getAllDrugs(); // Make sure this method exists

      if (mounted) {
        result.fold(
          (failure) {
            setState(
              () =>
                  _errorMessage =
                      "Failed to load drug list: ${failure.message}",
            );
            print("Error loading drugs: ${failure.message}");
          },
          (List<DrugEntity> drugs) {
            // Explicitly type drugs
            setState(() => _allDrugs = drugs);
            print(
              "InteractionCheckerScreen: Loaded ${_allDrugs.length} drugs.",
            );
          },
        );
      }
    } catch (e, stacktrace) {
      if (mounted) {
        setState(() => _errorMessage = "Error loading drugs: $e");
      }
      print("Error loading drugs: $e");
      print("Stacktrace: $stacktrace");
    }
  }

  Future<void> _ensureInteractionDataLoaded() async {
    // Attempt to load interaction data if not already loaded
    // This is a fallback; ideally, it's loaded during app initialization
    final result = await _interactionRepository.loadInteractionData();
    result.fold((failure) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load interaction data: ${failure.message}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error loading interaction database: ${failure.message}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }, (_) => print("Interaction data ensured/loaded successfully."));
  }

  Future<void> _checkInteractions() async {
    if (_selectedDrug1 == null || _selectedDrug2 == null) {
      setState(() {
        _errorMessage = "Please select two drugs to compare.";
        _interactions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _interactions = [];
    });

    final result = await _interactionRepository.findInteractionsForMedicines([
      _selectedDrug1!,
      _selectedDrug2!,
    ]);

    if (mounted) {
      setState(() {
        result.fold(
          (failure) {
            _errorMessage = "Error checking interactions: ${failure.message}";
            _interactions = [];
          },
          (interactions) {
            _interactions = interactions;
            if (interactions.isEmpty) {
              _errorMessage =
                  "No interactions found between the selected drugs.";
            }
          },
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access MedicineProvider if needed for drug list
    // final medicineProvider = Provider.of<MedicineProvider>(context);
    // _allDrugs = medicineProvider.drugs; // Example: Get drugs from provider state

    return Scaffold(
      appBar: AppBar(
        // title: Text(AppLocalizations.of(context)!.interactionCheckerTitle), // Use localization
        title: const Text('Drug Interaction Checker'), // Placeholder title
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Drug Selection ---
            // TODO: Replace with actual DrugSearchDelegate or CustomSearchableDropDown
            _buildDrugSelector(
              label: 'Select Drug 1', // Placeholder
              selectedDrug: _selectedDrug1,
              onChanged: (drug) => setState(() => _selectedDrug1 = drug),
            ),
            const SizedBox(height: 16),
            _buildDrugSelector(
              label: 'Select Drug 2', // Placeholder
              selectedDrug: _selectedDrug2,
              onChanged: (drug) => setState(() => _selectedDrug2 = drug),
            ),
            const SizedBox(height: 24),

            // --- Check Button ---
            ElevatedButton(
              onPressed:
                  (_selectedDrug1 != null &&
                          _selectedDrug2 != null &&
                          !_isLoading)
                      ? _checkInteractions
                      : null,
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      // : Text(AppLocalizations.of(context)!.checkInteractionsButton), // Use localization
                      : const Text('Check Interactions'), // Placeholder
            ),
            const SizedBox(height: 24),

            // --- Results Area ---
            if (_errorMessage != null && !_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color:
                        _interactions.isEmpty ? Colors.grey[600] : Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            Expanded(
              child:
                  _isLoading && _interactions.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _interactions.isEmpty &&
                          _errorMessage == null &&
                          !_isLoading
                      ? const Center(
                        child: Text(
                          'Select two drugs and press "Check Interactions".',
                        ),
                      ) // Placeholder
                      : ListView.builder(
                        itemCount: _interactions.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InteractionCard(
                              interaction: _interactions[index],
                              // Optional: Pass drug names if needed by the card
                              // drug1Name: _selectedDrug1?.tradeName,
                              // drug2Name: _selectedDrug2?.tradeName,
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds a button that opens the DrugSearchDelegate
  Widget _buildDrugSelector({
    required String label,
    required DrugEntity? selectedDrug,
    required ValueChanged<DrugEntity?> onChanged,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        textStyle: Theme.of(context).textTheme.titleMedium,
        foregroundColor:
            selectedDrug != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).hintColor,
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      onPressed: () async {
        // Ensure _allDrugs is loaded before showing search
        if (_allDrugs.isEmpty && _errorMessage == null) {
          // Optionally show a loading indicator or message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loading drug list... Please wait.')),
          );
          await _loadAllDrugs(); // Attempt to load again if empty
          if (_allDrugs.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to load drug list. Cannot search.'),
                backgroundColor: Colors.red,
              ),
            );
            return; // Don't open search if still empty
          }
        } else if (_errorMessage != null && _allDrugs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $_errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
          return; // Don't open search if there was an error loading
        }

        final DrugEntity? result = await showSearch<DrugEntity?>(
          context: context,
          delegate: DrugSearchDelegate(
            // Removed allDrugs parameter, as the delegate uses MedicineProvider
            // Optional: Customize hint text
            // searchFieldLabel: 'Search Drugs...',
          ),
        );
        if (result != null) {
          onChanged(result); // Update the state with the selected drug
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              selectedDrug?.tradeName ?? label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    selectedDrug != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).hintColor,
                fontWeight:
                    selectedDrug != null ? FontWeight.normal : FontWeight.w400,
              ),
            ),
          ),
          const Icon(Icons.search),
        ],
      ),
    );
  }
}
