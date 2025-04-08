import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/admob_config_entity.dart';
import '../repositories/config_repository.dart';

class GetAdMobConfig implements UseCase<AdMobConfigEntity, NoParams> {
  final ConfigRepository repository;

  GetAdMobConfig(this.repository);

  @override
  Future<Either<Failure, AdMobConfigEntity>> call(NoParams params) async {
    return await repository.getAdMobConfig();
  }
}
