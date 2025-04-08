import '../../domain/entities/general_config_entity.dart';

class GeneralConfigModel extends GeneralConfigEntity {
  const GeneralConfigModel({
    required super.termsUrl,
    required super.privacyUrl,
    required super.aboutUrl,
  });

  factory GeneralConfigModel.fromJson(Map<String, dynamic> json) {
    return GeneralConfigModel(
      termsUrl: json['terms_url'] as String? ?? '',
      privacyUrl: json['privacy_url'] as String? ?? '',
      aboutUrl: json['about_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'terms_url': termsUrl,
      'privacy_url': privacyUrl,
      'about_url': aboutUrl,
    };
  }
}
