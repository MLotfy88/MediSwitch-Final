import 'package:flutter/material.dart';
import '../../domain/entities/drug_entity.dart';

// Helper widget for displaying a drug item in the list/grid
class DrugListItem extends StatelessWidget {
  final DrugEntity drug;
  final VoidCallback onTap;

  const DrugListItem({
    super.key, // Add super.key
    required this.drug,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 8.0, // Adjusted margin for grid/list flexibility
        vertical: 6.0,
      ),
      child: ListTile(
        title: Text(
          drug.tradeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1, // Prevent long names from wrapping excessively
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
          children: [
            Text(drug.arabicName, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2.0),
            Text(
              'السعر: ${drug.price} جنيه',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (drug.mainCategory.isNotEmpty)
              Text(
                'الفئة: ${drug.mainCategory}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        isThreeLine: false, // Let subtitle height be dynamic
        onTap: onTap,
      ),
    );
  }
}
