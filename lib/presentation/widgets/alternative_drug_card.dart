import 'package:flutter/material.dart';
import '../../domain/entities/drug_entity.dart';

class AlternativeDrugCard extends StatelessWidget {
  final DrugEntity drug;
  final VoidCallback? onTap; // Optional callback for when the card is tapped

  const AlternativeDrugCard({super.key, required this.drug, this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: 2, // Add subtle shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Rounded corners
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        leading: Icon(
          Icons.medication_liquid_outlined, // Generic medication icon
          color: colorScheme.primary,
          size: 36,
        ),
        title: Text(
          drug.tradeName,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle:
            drug.arabicName.isNotEmpty
                ? Text(
                  drug.arabicName,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
                : null, // Don't show subtitle if arabicName is empty
        trailing: Text(
          '${drug.price} جنيه', // EGP or appropriate currency symbol
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap, // Assign the onTap callback
      ),
    );
  }
}
