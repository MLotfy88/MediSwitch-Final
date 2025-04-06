class MedicineModel {
  final String tradeName;
  final String arabicName;
  final String oldPrice;
  final String price;
  final String active;
  final String mainCategory;
  final String mainCategoryAr;
  final String category;
  final String categoryAr;
  final String company;
  final String dosageForm;
  final String dosageFormAr;
  final String unit;
  final String usage;
  final String usageAr;
  final String description;
  final String lastPriceUpdate;
  final double? concentration; // Added for dosage calculation
  final String? imageUrl; // Optional image URL

  // معرف اختياري للاستخدام مع قاعدة البيانات
  final int? id;

  MedicineModel({
    required this.tradeName,
    required this.arabicName,
    required this.oldPrice,
    required this.price,
    required this.active,
    required this.mainCategory,
    required this.mainCategoryAr,
    required this.category,
    required this.categoryAr,
    required this.company,
    required this.dosageForm,
    required this.dosageFormAr,
    required this.unit,
    required this.usage,
    required this.usageAr,
    required this.description,
    required this.lastPriceUpdate,
    this.concentration, // Added for dosage calculation
    this.imageUrl, // Add to constructor
    this.id,
  });

  factory MedicineModel.fromCsv(List<dynamic> row) {
    return MedicineModel(
      // Safely convert dynamic row elements to String
      tradeName: row.length > 0 ? row[0]?.toString() ?? '' : '',
      arabicName: row.length > 1 ? row[1]?.toString() ?? '' : '',
      oldPrice: row.length > 2 ? row[2]?.toString() ?? '' : '',
      price: row.length > 3 ? row[3]?.toString() ?? '' : '',
      active: row.length > 4 ? row[4]?.toString() ?? '' : '',
      mainCategory: row.length > 5 ? row[5]?.toString() ?? '' : '',
      mainCategoryAr: row.length > 6 ? row[6]?.toString() ?? '' : '',
      category: row.length > 7 ? row[7]?.toString() ?? '' : '',
      categoryAr: row.length > 8 ? row[8]?.toString() ?? '' : '',
      company: row.length > 9 ? row[9]?.toString() ?? '' : '',
      dosageForm: row.length > 10 ? row[10]?.toString() ?? '' : '',
      dosageFormAr: row.length > 11 ? row[11]?.toString() ?? '' : '',
      unit: row.length > 12 ? row[12]?.toString() ?? '' : '',
      usage: row.length > 13 ? row[13]?.toString() ?? '' : '',
      usageAr: row.length > 14 ? row[14]?.toString() ?? '' : '',
      description: row.length > 15 ? row[15]?.toString() ?? '' : '',
      lastPriceUpdate: row.length > 16 ? row[16]?.toString() ?? '' : '',
      // Assuming concentration is in the next column (index 17)
      concentration:
          row.length > 17 ? double.tryParse(row[17]?.toString() ?? '') : null,
      // Assuming image_url is in the next column (index 18)
      imageUrl: row.length > 18 ? row[18]?.toString() : null,
    );
  }

  // تحويل النموذج إلى Map لاستخدامه مع قاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      'tradeName': tradeName,
      'arabicName': arabicName,
      'oldPrice': oldPrice,
      'price': price,
      'active': active,
      'mainCategory': mainCategory,
      'mainCategoryAr': mainCategoryAr,
      'category': category,
      'categoryAr': categoryAr,
      'company': company,
      'dosageForm': dosageForm,
      'dosageFormAr': dosageFormAr,
      'unit': unit,
      'usage': usage,
      'usageAr': usageAr,
      'description': description,
      'lastPriceUpdate': lastPriceUpdate,
      'concentration': concentration, // Added for dosage calculation
      'imageUrl': imageUrl, // Add to map
    };
  }

  // إنشاء نموذج من Map من قاعدة البيانات
  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      // Safely cast map values
      id: map['id'] as int?, // Cast id to int?
      tradeName: map['tradeName']?.toString() ?? '',
      arabicName: map['arabicName']?.toString() ?? '',
      oldPrice: map['oldPrice']?.toString() ?? '',
      price: map['price']?.toString() ?? '',
      active: map['active']?.toString() ?? '',
      mainCategory: map['mainCategory']?.toString() ?? '',
      mainCategoryAr: map['mainCategoryAr']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      categoryAr: map['categoryAr']?.toString() ?? '',
      company: map['company']?.toString() ?? '',
      dosageForm: map['dosageForm']?.toString() ?? '',
      dosageFormAr: map['dosageFormAr']?.toString() ?? '',
      unit: map['unit']?.toString() ?? '',
      usage: map['usage']?.toString() ?? '',
      usageAr: map['usageAr']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      lastPriceUpdate: map['lastPriceUpdate']?.toString() ?? '',
      // Safely parse concentration from map
      concentration:
          map['concentration'] != null
              ? double.tryParse(map['concentration'].toString())
              : null,
      imageUrl: map['imageUrl']?.toString(), // Add from map
    );
  }

  @override
  String toString() {
    return '$tradeName - $arabicName - $price';
  }
}
