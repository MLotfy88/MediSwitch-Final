import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/general_config_entity.dart';
import '../repositories/config_repository.dart';

class GetGeneralConfig implements UseCase<GeneralConfigEntity, NoParams> {
  final ConfigRepository repository;

  GetGeneralConfig(this.repository);

  @override
  Future<Either<Failure, GeneralConfigEntity>> call(NoParams params) async {
    return await repository.getGeneralConfig();
  }
}
