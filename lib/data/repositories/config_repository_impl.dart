import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/admob_config_entity.dart';
import '../../domain/entities/general_config_entity.dart';
import '../../domain/repositories/config_repository.dart';
import '../datasources/remote/config_remote_data_source.dart';
// TODO: Import local data source if caching is implemented

class ConfigRepositoryImpl implements ConfigRepository {
  final ConfigRemoteDataSource remoteDataSource;
  // final ConfigLocalDataSource localDataSource; // Add if caching
  // final NetworkInfo networkInfo; // Add for checking connectivity

  ConfigRepositoryImpl({
    required this.remoteDataSource,
    // required this.localDataSource,
    // required this.networkInfo,
  });

  @override
  Future<Either<Failure, AdMobConfigEntity>> getAdMobConfig() async {
    // TODO: Add network check and caching logic later
    try {
      final remoteConfig = await remoteDataSource.getAdMobConfig();
      // TODO: Cache remoteConfig locally
      return Right(
        remoteConfig,
      ); // remoteConfig is already an AdMobConfigModel which extends AdMobConfigEntity
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      // Catch any other unexpected errors
      print('Unexpected error in getAdMobConfig: $e');
      return Left(
        ServerFailure(
          message: 'An unexpected error occurred while fetching AdMob config.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, GeneralConfigEntity>> getGeneralConfig() async {
    // TODO: Add network check and caching logic later
    try {
      final remoteConfig = await remoteDataSource.getGeneralConfig();
      // TODO: Cache remoteConfig locally
      return Right(
        remoteConfig,
      ); // remoteConfig is already a GeneralConfigModel which extends GeneralConfigEntity
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      // Catch any other unexpected errors
      print('Unexpected error in getGeneralConfig: $e');
      return Left(
        ServerFailure(
          message:
              'An unexpected error occurred while fetching general config.',
        ),
      );
    }
  }
}
