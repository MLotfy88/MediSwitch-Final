import 'package:mediswitch/domain/entities/drug_entity.dart';
import 'package:mediswitch/presentation/widgets/home/drug_card.dart';

/// Converts DrugEntity to DrugUIModel for display in DrugCard
DrugUIModel drugEntityToUIModel(
  DrugEntity entity, {
  bool isFavorite = false,
  bool? isPopularOverride,
}) {
  // Parse current price
  final currentPrice = double.tryParse(entity.price) ?? 0.0;

  // Parse old price if available
  final oldPrice =
      entity.oldPrice != null && entity.oldPrice!.isNotEmpty
          ? double.tryParse(entity.oldPrice!)
          : null;

  return DrugUIModel(
    id: entity.id.toString(),
    tradeNameEn: entity.tradeName,
    tradeNameAr: entity.arabicName,
    activeIngredient: entity.active,
    form: entity.dosageForm,
    currentPrice: currentPrice,
    oldPrice: oldPrice,
    company: entity.company,
    isFavorite: isFavorite,
    isNew: entity.isNew,
    isPopular: isPopularOverride ?? entity.isPopular,
    hasInteraction: entity.hasDrugInteraction || entity.hasFoodInteraction,
  );
}
