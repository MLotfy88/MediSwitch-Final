import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/drug_entity.dart';
import '../bloc/alternatives_provider.dart';
import '../widgets/alternative_drug_card.dart'; // Import the new card widget

class AlternativesScreen extends StatefulWidget {
  final DrugEntity originalDrug;

  const AlternativesScreen({super.key, required this.originalDrug});

  @override
  State<AlternativesScreen> createState() => _AlternativesScreenState();
}

class _AlternativesScreenState extends State<AlternativesScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger finding alternatives when the screen is initialized
    // Use addPostFrameCallback to ensure provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlternativesProvider>().findAlternativesFor(
        widget.originalDrug,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlternativesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('بدائل ${widget.originalDrug.tradeName}'),
        centerTitle: true,
        elevation: 1, // Subtle elevation
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 20.0,
        ), // Increased vertical padding
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch children horizontally
          children: [
            // Display Original Drug Info (Optional) - Styled Card
            Card(
              elevation: 0,
              color: Theme.of(
                context,
              ).colorScheme.secondaryContainer.withOpacity(0.3),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الدواء الأصلي', // Clearer title
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.originalDrug.tradeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    if (widget.originalDrug.mainCategory.isNotEmpty)
                      Text(
                        'الفئة: ${widget.originalDrug.mainCategory}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // const Divider(height: 24), // Removed divider, using card separation

            // Display Alternatives Title
            Padding(
              padding: const EdgeInsets.only(
                bottom: 12.0,
              ), // Increased spacing below title
              child: Text(
                'البدائل المقترحة (نفس الفئة)', // Slightly more descriptive title
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
            ),
            // const SizedBox(height: 8), // Replaced with Padding above

            // Loading/Error/List View
            if (provider.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (provider.error.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    provider.error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (provider.alternatives.isEmpty)
              const Expanded(
                child: Center(child: Text('لا توجد بدائل متاحة لهذه الفئة.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: provider.alternatives.length,
                  itemBuilder: (context, index) {
                    final alternative = provider.alternatives[index];
                    // Use the new AlternativeDrugCard
                    return AlternativeDrugCard(
                      drug: alternative,
                      onTap: () {
                        // Optional: Navigate to details of the alternative?
                        // Maybe show the same _showMedicineDetails modal from HomeScreen?
                        print(
                          'Tapped on alternative: ${alternative.tradeName}',
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
