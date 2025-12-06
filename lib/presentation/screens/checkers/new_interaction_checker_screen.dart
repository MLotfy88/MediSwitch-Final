import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Modern Interaction Checker Screen
/// Enhanced design matching app style
class NewInteractionCheckerScreen extends StatefulWidget {
  const NewInteractionCheckerScreen({super.key});

  @override
  State<NewInteractionCheckerScreen> createState() =>
      _NewInteractionCheckerScreenState();
}

class _NewInteractionCheckerScreenState
    extends State<NewInteractionCheckerScreen> {
  final List<String> _selectedDrugs = [];
  final List<_Interaction> _interactions = [];

  void _addDrug(String drugName) {
    if (!_selectedDrugs.contains(drugName)) {
      setState(() {
        _selectedDrugs.add(drugName);
        _checkInteractions();
      });
    }
  }

  void _removeDrug(String drugName) {
    setState(() {
      _selectedDrugs.remove(drugName);
      _checkInteractions();
    });
  }

  void _checkInteractions() {
    // Mock interaction check - replace with actual logic
    _interactions.clear();

    if (_selectedDrugs.contains('Warfarin') &&
        _selectedDrugs.contains('Aspirin')) {
      _interactions.add(
        _Interaction(
          drug1: 'Warfarin',
          drug2: 'Aspirin',
          severity: 'major',
          description: 'Increased risk of bleeding',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade700,
              Colors.orange.shade600,
              Colors.orange.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        LucideIcons.arrowLeft,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRTL ? 'فحص التفاعلات' : 'Interaction Checker',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isRTL
                                ? 'تحقق من التفاعلات بين الأدوية'
                                : 'Check drug interactions',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Selected Drugs
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isRTL ? 'الأدوية المحددة' : 'Selected Drugs',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_selectedDrugs.length} drugs',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Add Drug Button
                            OutlinedButton.icon(
                              onPressed: () => _showAddDrugDialog(context),
                              icon: const Icon(LucideIcons.plus, size: 18),
                              label: Text(isRTL ? 'إضافة دواء' : 'Add Drug'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: colorScheme.primary),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Drug Chips
                            if (_selectedDrugs.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _selectedDrugs.map((drug) {
                                      return Chip(
                                        label: Text(drug),
                                        deleteIcon: const Icon(
                                          LucideIcons.x,
                                          size: 16,
                                        ),
                                        onDeleted: () => _removeDrug(drug),
                                        backgroundColor:
                                            colorScheme.primaryContainer,
                                      ).animate().fadeIn().scale();
                                    }).toList(),
                              )
                            else
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Column(
                                    children: [
                                      Icon(
                                        LucideIcons.pill,
                                        size: 48,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        isRTL
                                            ? 'لم يتم تحديد أدوية'
                                            : 'No drugs selected',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.5),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Results
                      Expanded(
                        child:
                            _interactions.isEmpty
                                ? _buildEmptyState(context, isRTL)
                                : ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _interactions.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    return _buildInteractionCard(
                                      context,
                                      _interactions[index],
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isRTL) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.checkCircle,
                size: 50,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isRTL ? 'لا توجد تفاعلات' : 'No Interactions Found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.tertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRTL
                  ? 'الأدوية المحددة آمنة لاستخدامها معاً'
                  : 'Selected drugs are safe to use together',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionCard(BuildContext context, _Interaction interaction) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final severityColor =
        interaction.severity == 'major'
            ? colorScheme.error
            : interaction.severity == 'moderate'
            ? Colors.orange
            : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  interaction.severity.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(LucideIcons.alertTriangle, size: 20, color: severityColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${interaction.drug1} + ${interaction.drug2}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            interaction.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  void _showAddDrugDialog(BuildContext context) {
    final mockDrugs = [
      'Warfarin',
      'Aspirin',
      'Metformin',
      'Lisinopril',
      'Atorvastatin',
    ];

    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Drug',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                ...mockDrugs.map((drug) {
                  return ListTile(
                    title: Text(drug),
                    trailing: const Icon(LucideIcons.plus),
                    onTap: () {
                      _addDrug(drug);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
    );
  }
}

class _Interaction {
  final String drug1;
  final String drug2;
  final String severity;
  final String description;

  _Interaction({
    required this.drug1,
    required this.drug2,
    required this.severity,
    required this.description,
  });
}
