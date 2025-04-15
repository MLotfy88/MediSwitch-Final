import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/drug_entity.dart';

class DrugSelectionDialog extends StatefulWidget {
  final List<DrugEntity> allDrugs;
  final List<DrugEntity> alreadySelectedDrugs;

  const DrugSelectionDialog({
    super.key,
    required this.allDrugs,
    required this.alreadySelectedDrugs,
  });

  @override
  State<DrugSelectionDialog> createState() => _DrugSelectionDialogState();
}

class _DrugSelectionDialogState extends State<DrugSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<DrugEntity> _filteredDrugs = [];
  DrugEntity? _currentlySelectedInDialog; // Track selection within the dialog

  @override
  void initState() {
    super.initState();
    // Initially show all drugs that are not already selected
    _filteredDrugs =
        widget.allDrugs
            .where(
              (drug) =>
                  !widget.alreadySelectedDrugs.any(
                    (selected) => selected.tradeName == drug.tradeName,
                  ),
            )
            .toList();
    _searchController.addListener(_filterDrugs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDrugs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDrugs =
          widget.allDrugs.where((drug) {
            final isAlreadySelected = widget.alreadySelectedDrugs.any(
              (selected) => selected.tradeName == drug.tradeName,
            );
            if (isAlreadySelected) return false; // Exclude already selected

            return drug.tradeName.toLowerCase().contains(query) ||
                drug.arabicName.toLowerCase().contains(query) ||
                drug.active.toLowerCase().contains(query);
          }).toList();
      // Clear dialog selection if search changes
      _currentlySelectedInDialog = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('اختر دواء لإضافته'),
      contentPadding: const EdgeInsets.fromLTRB(8, 16, 8, 8), // Reduced padding
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6, // Limit height
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Field within Dialog
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ابحث هنا...',
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 20,
                    color: theme.hintColor,
                  ),
                  isDense: true, // Make it more compact
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(LucideIcons.x, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              // Reset selection when clearing search
                              setState(() {
                                _currentlySelectedInDialog = null;
                              });
                            },
                            splashRadius: 20,
                          )
                          : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // List of Drugs
            Expanded(
              child:
                  _filteredDrugs.isEmpty
                      ? Center(
                        child: Text(
                          'لا توجد أدوية مطابقة.',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredDrugs.length,
                        itemBuilder: (context, index) {
                          final drug = _filteredDrugs[index];
                          final bool isSelectedInDialog =
                              _currentlySelectedInDialog?.tradeName ==
                              drug.tradeName;
                          return ListTile(
                            title: Text(drug.tradeName),
                            subtitle: Text(
                              drug.active,
                              style: theme.textTheme.bodySmall,
                            ),
                            selected: isSelectedInDialog,
                            selectedTileColor: colorScheme.primary.withOpacity(
                              0.1,
                            ),
                            onTap: () {
                              setState(() {
                                _currentlySelectedInDialog =
                                    drug; // Update selection within dialog
                              });
                            },
                            dense: true,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            if (_currentlySelectedInDialog != null) {
              Navigator.pop(
                context,
                _currentlySelectedInDialog,
              ); // Return the selected drug
            } else {
              // Optionally show message if nothing is selected in the dialog
            }
          },
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}
