import 'package:mediswitch/domain/entities/category_entity.dart';

/// Category Mapping Dictionary
/// يربط أسماء التخصصات الحقيقية من Database بالأسماء المطلوبة في التصميم المرجعي
class CategoryMapper {
  // التخصصات المطلوبة في التصميم (من mediswitch-refresh)
  // Design Reference Categories with unique icons and colors
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

  // Comprehensive mapping dictionary: Database Category Name -> Reference Category Name
  // Maps all possible database category variations to our 6 design reference categories
  static const Map<String, String> realToReferenceName = {
    // Cardiac (Heart) - Red
    'cardiology': 'Cardiac',
    'cardiovascular': 'Cardiac',
    'heart': 'Cardiac',
    'cardiac': 'Cardiac',
    'cardio': 'Cardiac',
    'blood pressure': 'Cardiac',
    'hypertension': 'Cardiac',
    'antihypertensive': 'Cardiac',
    'antihypertensives': 'Cardiac',
    'heart disease': 'Cardiac',
    'القلب': 'Cardiac',
    'أمراض القلب': 'Cardiac',

    // Neuro (Brain/Nerves) - Purple
    'neurology': 'Neuro',
    'neurological': 'Neuro',
    'neuro': 'Neuro',
    'brain': 'Neuro',
    'nervous': 'Neuro',
    'psychiatric': 'Neuro',
    'psychiatry': 'Neuro',
    'mental health': 'Neuro',
    'antipsychotic': 'Neuro',
    'antipsychotics': 'Neuro',
    'antidepressant': 'Neuro',
    'antidepressants': 'Neuro',
    'anxiety': 'Neuro',
    'epilepsy': 'Neuro',
    'anticonvulsant': 'Neuro',
    'anticonvulsants': 'Neuro',
    'sedative': 'Neuro',
    'sedatives': 'Neuro',
    'الأعصاب': 'Neuro',
    'الجهاز العصبي': 'Neuro',
    'نفسية': 'Neuro',

    // Dental (Teeth/Mouth) - Teal
    'dentistry': 'Dental',
    'dental': 'Dental',
    'dental care': 'Dental',
    'teeth': 'Dental',
    'oral': 'Dental',
    'oral care': 'Dental',
    'mouth': 'Dental',
    'الأسنان': 'Dental',
    'العناية بالفم': 'Dental',

    // Pediatric (Children) - Green
    'pediatrics': 'Pediatric',
    'pediatric': 'Pediatric',
    'children': 'Pediatric',
    'kids': 'Pediatric',
    'baby': 'Pediatric',
    'baby care': 'Pediatric',
    'infant': 'Pediatric',
    'neonatal': 'Pediatric',
    'child health': 'Pediatric',
    'الأطفال': 'Pediatric',
    'طب الأطفال': 'Pediatric',
    'رعاية الأطفال': 'Pediatric',

    // Ophthalmic (Eyes/Vision) - Blue
    'ophthalmology': 'Ophthalmic',
    'ophthalmic': 'Ophthalmic',
    'eye care': 'Ophthalmic',
    'eye': 'Ophthalmic',
    'eyes': 'Ophthalmic',
    'vision': 'Ophthalmic',
    'ocular': 'Ophthalmic',
    'العيون': 'Ophthalmic',
    'طب العيون': 'Ophthalmic',
    'رعاية العيون': 'Ophthalmic',

    // Orthopedic (Bones/Muscles) - Orange
    'orthopedics': 'Orthopedic',
    'orthopedic': 'Orthopedic',
    'orthopaedic': 'Orthopedic',
    'bones': 'Orthopedic',
    'bone': 'Orthopedic',
    'skeletal': 'Orthopedic',
    'musculoskeletal': 'Orthopedic',
    'joints': 'Orthopedic',
    'rheumatology': 'Orthopedic',
    'arthritis': 'Orthopedic',
    'العظام': 'Orthopedic',
    'طب العظام': 'Orthopedic',
    'المفاصل': 'Orthopedic',
  };

  /// Maps a database category name to a reference category name (case-insensitive)
  static String? getReferenceCategoryName(String dbCategoryName) {
    final lowerName = dbCategoryName.toLowerCase().trim();

    // Direct match first
    if (realToReferenceName.containsKey(lowerName)) {
      return realToReferenceName[lowerName];
    }

    // Partial match - check if any key is contained in the category name
    for (final entry in realToReferenceName.entries) {
      if (lowerName.contains(entry.key) || entry.key.contains(lowerName)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Get reference category data by name
  static Map<String, dynamic>? getReferenceCategoryData(String refName) {
    try {
      return referenceCategories.firstWhere((cat) => cat['name'] == refName);
    } catch (_) {
      return null;
    }
  }

  /// Convert a map of database categories with counts to CategoryEntity list
  /// Prioritizes categories that match our 6 reference categories
  static List<CategoryEntity> mapCategoriesWithCounts(
    Map<String, int> categoryCounts,
  ) {
    final List<CategoryEntity> result = [];
    final Set<String> usedReferenceCategories = {};

    // First pass: Map database categories to reference categories
    final Map<String, ({int count, String originalName})> refCategoryData = {};

    for (final entry in categoryCounts.entries) {
      final dbCategory = entry.key;
      final count = entry.value;
      final refName = getReferenceCategoryName(dbCategory);

      if (refName != null) {
        // Aggregate counts for same reference category
        if (refCategoryData.containsKey(refName)) {
          final existing = refCategoryData[refName]!;
          refCategoryData[refName] = (
            count: existing.count + count,
            originalName: existing.originalName,
          );
        } else {
          refCategoryData[refName] = (count: count, originalName: dbCategory);
        }
      }
    }

    // Sort reference categories by count (descending) and take top 6
    final sortedRefCategories =
        refCategoryData.entries.toList()
          ..sort((a, b) => b.value.count.compareTo(a.value.count));

    for (final entry in sortedRefCategories.take(6)) {
      final refName = entry.key;
      final data = entry.value;
      final refData = getReferenceCategoryData(refName);

      if (refData != null) {
        result.add(
          CategoryEntity(
            id: refData['id'] as String,
            name: refData['name'] as String,
            nameAr: refData['nameAr'] as String,
            icon: refData['icon'] as String,
            color: refData['color'] as String,
            drugCount: data.count,
          ),
        );
        usedReferenceCategories.add(refName);
      }
    }

    // If we have less than 6, fill with remaining reference categories
    if (result.length < 6) {
      for (final refData in referenceCategories) {
        if (!usedReferenceCategories.contains(refData['name'])) {
          result.add(
            CategoryEntity(
              id: refData['id'] as String,
              name: refData['name'] as String,
              nameAr: refData['nameAr'] as String,
              icon: refData['icon'] as String,
              color: refData['color'] as String,
              drugCount: 0,
            ),
          );
          if (result.length >= 6) break;
        }
      }
    }

    return result;
  }

  /// تحويل CategoryEntity من البيانات الحقيقية إلى CategoryEntity مطابق للتصميم
  static CategoryEntity mapToReferenceCategory(CategoryEntity realCategory) {
    final mappedName =
        getReferenceCategoryName(realCategory.name) ??
        getReferenceCategoryName(realCategory.nameAr);

    if (mappedName != null) {
      final refData = getReferenceCategoryData(mappedName);

      if (refData != null) {
        return CategoryEntity(
          id: realCategory.id,
          name: refData['name'] as String,
          nameAr: refData['nameAr'] as String,
          icon: refData['icon'] as String,
          color: refData['color'] as String,
          drugCount: realCategory.drugCount,
        );
      }
    }

    // If no match, return original with default icon/color
    return CategoryEntity(
      id: realCategory.id,
      name: realCategory.name,
      nameAr: realCategory.nameAr,
      icon: realCategory.icon ?? 'pill',
      color: realCategory.color ?? 'blue',
      drugCount: realCategory.drugCount,
    );
  }

  /// تحويل قائمة كاملة من CategoryEntity
  static List<CategoryEntity> mapCategories(
    List<CategoryEntity> realCategories,
  ) {
    final mapped = realCategories.map(mapToReferenceCategory).toList();

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
                  drugCount: 0,
                ),
              )
              .toList();

      return [...mapped, ...remaining];
    }

    return mapped.take(6).toList();
  }
}
