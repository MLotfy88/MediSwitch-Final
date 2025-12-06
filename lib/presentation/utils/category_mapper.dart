import 'package:mediswitch/domain/entities/category_entity.dart';

/// Category Mapping Dictionary
/// يربط أسماء التخصصات الحقيقية من Database بالأسماء المطلوبة في التصميم المرجعي
class CategoryMapper {
  // التخصصات المطلوبة في التصميم (من mediswitch-refresh)
  static const List<Map<String, dynamic>> referenceCategories = [
    {
      'id': '1',
      'name': 'Cardiac',
      'nameAr': 'قلب',
      'icon': 'heart',
      'color': 'red',
    },
    {
      'id': '2',
      'name': 'Neuro',
      'nameAr': 'أعصاب',
      'icon': 'brain',
      'color': 'purple',
    },
    {
      'id': '3',
      'name': 'Dental',
      'nameAr': 'أسنان',
      'icon': 'smile',
      'color': 'teal',
    },
    {
      'id': '4',
      'name': 'Pediatric',
      'nameAr': 'أطفال',
      'icon': 'baby',
      'color': 'green',
    },
    {
      'id': '5',
      'name': 'Ophthalmic',
      'nameAr': 'عيون',
      'icon': 'eye',
      'color': 'blue',
    },
    {
      'id': '6',
      'name': 'Orthopedic',
      'nameAr': 'عظام',
      'icon': 'bone',
      'color': 'orange',
    },
  ];

  // قاموس ربط الأسماء الحقيقية بالأسماء المرجعية
  static const Map<String, String> realToReferenceName = {
    // مثال: إذا كانت البيانات الحقيقية تحتوي على "Cardiology" نربطها بـ "Cardiac"
    'Cardiology': 'Cardiac',
    'Cardiovascular': 'Cardiac',
    'Heart': 'Cardiac',
    'القلب': 'Cardiac',

    'Neurology': 'Neuro',
    'Neurological': 'Neuro',
    'Brain': 'Neuro',
    'الأعصاب': 'Neuro',

    'Dentistry': 'Dental',
    'Dental Care': 'Dental',
    'Teeth': 'Dental',
    'الأسنان': 'Dental',

    'Pediatrics': 'Pediatric',
    'Children': 'Pediatric',
    'Kids': 'Pediatric',
    'الأطفال': 'Pediatric',

    'Ophthalmology': 'Ophthalmic',
    'Eye Care': 'Ophthalmic',
    'Vision': 'Ophthalmic',
    'العيون': 'Ophthalmic',

    'Orthopedics': 'Orthopedic',
    'Bones': 'Orthopedic',
    'Skeletal': 'Orthopedic',
    'العظام': 'Orthopedic',
  };

  /// تحويل CategoryEntity من البيانات الحقيقية إلى CategoryEntity مطابق للتصميم
  static CategoryEntity mapToReferenceCategory(CategoryEntity realCategory) {
    // البحث عن التخصص المناسب في القاموس
    final mappedName =
        realToReferenceName[realCategory.name] ??
        realToReferenceName[realCategory.nameAr];

    if (mappedName != null) {
      // إيجاد البيانات المرجعية المطابقة
      final refData = referenceCategories.firstWhere(
        (cat) => cat['name'] == mappedName,
        orElse: () => referenceCategories[0], // fallback to Cardiac
      );

      return CategoryEntity(
        id: realCategory.id,
        name: refData['name'] as String,
        nameAr: refData['nameAr'] as String,
        icon: refData['icon'] as String,
        color: refData['color'] as String,
        drugCount: realCategory.drugCount,
      );
    }

    // إذا لم نجد تطابق، نرجع البيانات الأصلية
    return realCategory;
  }

  /// تحويل قائمة كاملة من CategoryEntity
  static List<CategoryEntity> mapCategories(
    List<CategoryEntity> realCategories,
  ) {
    // نحاول تطبيق الـ mapping على كل تخصص
    final mapped = realCategories.map(mapToReferenceCategory).toList();

    // إذا كانت القائمة أقل من 6، نكمل من referenceCategories
    if (mapped.length < 6) {
      final usedNames = mapped.map((c) => c.name).toSet();
      final remaining =
          referenceCategories
              .where((ref) => !usedNames.contains(ref['name']))
              .take(6 - mapped.length)
              .map(
                (ref) => CategoryEntity(
                  id: ref['id'] as String,
                  name: ref['name'] as String,
                  nameAr: ref['nameAr'] as String,
                  icon: ref['icon'] as String,
                  color: ref['color'] as String,
                  drugCount: 0, // عدد افتراضي
                ),
              )
              .toList();

      return [...mapped, ...remaining];
    }

    return mapped.take(6).toList();
  }
}
