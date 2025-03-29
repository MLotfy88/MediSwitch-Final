import 'package:flutter/material.dart';
import '../../domain/entities/drug_entity.dart';

class AlternativeDrugCard extends StatelessWidget {
  final DrugEntity drug;
  final VoidCallback? onTap; // Optional callback for when the card is tapped

  const AlternativeDrugCard({super.key, required this.drug, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        // Make the card tappable
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                drug.tradeName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (drug.arabicName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  drug.arabicName,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Optionally display Active Ingredient when available
                  // Text(
                  //   'المادة: ${drug.activeIngredient ?? 'غير معروف'}',
                  //   style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  // ),
                  Text(
                    'السعر: ${drug.price} جنيه',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
