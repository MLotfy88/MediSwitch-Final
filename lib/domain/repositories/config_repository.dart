import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart'; // Assuming Failure path
import '../entities/admob_config_entity.dart';
import '../entities/general_config_entity.dart';

abstract class ConfigRepository {
  /// Fetches the AdMob configuration from the backend or a local cache.
  Future<Either<Failure, AdMobConfigEntity>> getAdMobConfig();

  /// Fetches the General configuration (URLs, etc.) from the backend or local cache.
  Future<Either<Failure, GeneralConfigEntity>> getGeneralConfig();

  // Optional: Add methods to cache/update config if needed later
}
