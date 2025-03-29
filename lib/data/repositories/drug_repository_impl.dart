import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/drug_entity.dart';
import '../../domain/repositories/drug_repository.dart';
import '../datasources/local/csv_local_data_source.dart';
import '../datasources/remote/drug_remote_data_source.dart'; // Placeholder
import '../models/medicine_model.dart';
// import '../../core/network/network_info.dart'; // For checking connectivity

// Define specific Failure types (can be moved to failures.dart)
class CacheFailure extends Failure {}

class ServerFailure extends Failure {} // Example for remote source later

class DrugRepositoryImpl implements DrugRepository {
  final CsvLocalDataSource localDataSource;
  // final DrugRemoteDataSource remoteDataSource; // Uncomment when remote exists
  // final NetworkInfo networkInfo; // Uncomment when network info exists

  DrugRepositoryImpl({
    required this.localDataSource,
    // required this.remoteDataSource, // Uncomment when remote exists
    // required this.networkInfo, // Uncomment when network info exists
  });

  @override
  Future<Either<Failure, List<DrugEntity>>> getAllDrugs() async {
    // In a real scenario, you might check networkInfo here and decide
    // whether to fetch from remoteDataSource or localDataSource.
    // For now, we only have the local CSV source.
    try {
      final List<MedicineModel> localMedicines =
          await localDataSource.getAllMedicines();
      // Map List<MedicineModel> to List<DrugEntity>
      final List<DrugEntity> drugEntities =
          localMedicines.map((model) {
            return DrugEntity(
              tradeName: model.tradeName ?? '', // Handle potential nulls
              arabicName: model.arabicName ?? '',
              price: model.price ?? '',
              mainCategory: model.mainCategory ?? '',
              // Map other relevant fields here if added to DrugEntity
            );
          }).toList();
      return Right(drugEntities);
    } catch (e) {
      // Catch potential errors during local data fetching/parsing
      print('Cache Error in Repository: $e'); // Log the error
      return Left(CacheFailure()); // Return a specific Failure type
    }
  }

  // TODO: Implement other methods like searchDrugs, filterDrugsByCategory if defined in DrugRepository
}
