import 'package:equatable/equatable.dart';

class GeneralConfigEntity extends Equatable {
  final String termsUrl;
  final String privacyUrl;
  final String aboutUrl;
  // Add other general config fields as needed

  const GeneralConfigEntity({
    required this.termsUrl,
    required this.privacyUrl,
    required this.aboutUrl,
  });

  // Default empty state
  factory GeneralConfigEntity.empty() {
    return const GeneralConfigEntity(
      termsUrl: '',
      privacyUrl: '',
      aboutUrl: '',
    );
  }

  @override
  List<Object?> get props => [termsUrl, privacyUrl, aboutUrl];
}
