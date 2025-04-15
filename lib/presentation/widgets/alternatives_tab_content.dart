import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/di/locator.dart';
import '../../core/services/file_logger_service.dart';
import '../../domain/entities/drug_entity.dart';
import '../bloc/alternatives_provider.dart';
import 'drug_card.dart';
import '../screens/drug_details_screen.dart'; // Import DrugDetailsScreen

class AlternativesTabContent extends StatefulWidget {
  final DrugEntity originalDrug;

  const AlternativesTabContent({super.key, required this.originalDrug});

  @override
  State<AlternativesTabContent> createState() => _AlternativesTabContentState();
}

class _AlternativesTabContentState extends State<AlternativesTabContent> {
  final FileLoggerService _logger = locator<FileLoggerService>();

  @override
  void initState() {
    super.initState();
    _logger.d(
      "AlternativesTabContent: initState for drug: ${widget.originalDrug.tradeName}",
    );
    // Fetch alternatives when the tab is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _logger.i(
          "AlternativesTabContent: Fetching alternatives for ${widget.originalDrug.tradeName}",
        );
        // Correct method name
        context.read<AlternativesProvider>().findAlternativesFor(
          widget.originalDrug,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.d(
      "AlternativesTabContent: Building widget for drug: ${widget.originalDrug.tradeName}",
    );
    final provider = context.watch<AlternativesProvider>();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (provider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (provider.error.isNotEmpty)
          Center(
            child: Text(
              'خطأ: ${provider.error}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          )
        else if (provider.alternatives.isEmpty)
          const Center(child: Text('لا توجد بدائل متاحة بنفس المادة الفعالة.'))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.alternatives.length,
            itemBuilder: (context, index) {
              final alternative = provider.alternatives[index];
              return DrugCard(
                drug: alternative,
                type: DrugCardType.detailed,
                onTap: () {
                  _logger.i(
                    "AlternativesTabContent: Tapped alternative: ${alternative.tradeName}",
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      // Use correct screen name
                      builder:
                          (context) => DrugDetailsScreen(drug: alternative),
                    ),
                  );
                },
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          ),
      ],
    );
  }
}
