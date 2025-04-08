import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/error/failures.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/remote/analytics_remote_data_source.dart';
// TODO: Import NetworkInfo if needed for connectivity check

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo; // Add for checking connectivity

  AnalyticsRepositoryImpl({
    required this.remoteDataSource,
    // required this.networkInfo,
  });

  @override
  Future<Either<Failure, AnalyticsSummary>> getAnalyticsSummary() async {
    // TODO: Add network check later
    // if (await networkInfo.isConnected) {
    try {
      final remoteSummary = await remoteDataSource.getAnalyticsSummary();
      // The remote source returns AnalyticsSummary directly, which matches the required type
      return Right(remoteSummary);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print('Unexpected error in getAnalyticsSummary: $e');
      return Left(
        ServerFailure(
          message:
              'An unexpected error occurred while fetching analytics summary.',
        ),
      );
    }
    // } else {
    //   return Left(NetworkFailure(message: 'No internet connection.'));
    // }
  }
}
