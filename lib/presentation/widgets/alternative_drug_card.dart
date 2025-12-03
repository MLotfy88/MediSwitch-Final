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

    // Wrap Card with Semantics
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Semantics(
        label:
            'بديل: ${drug.tradeName}, السعر ${drug.price} جنيه', // Combined label
        button: onTap != null, // Indicate if it's tappable
        onTap: onTap,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8.0,
            horizontal: 16.0,
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
                  : null,
          trailing: Text(
            '${drug.price} جنيه',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
