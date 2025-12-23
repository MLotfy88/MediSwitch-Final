import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/services/file_logger_service.dart';
import 'package:mediswitch/domain/repositories/drug_repository.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnifiedSyncService {
  /// Service responsible for orchestrating synchronization across multiple repositories.
  UnifiedSyncService({
    required this.drugRepository,
    required this.interactionRepository,
    required this.logger,
  });

  /// Repository for drug-related data.
  final DrugRepository drugRepository;

  /// Repository for interaction-related data.
  final InteractionRepository interactionRepository;

  /// Logger service for debugging and tracking.
  final FileLoggerService logger;

  /// Performs a full synchronization of all data types from D1.
  /// Returns Right(true) if successful, Left(Failure) otherwise.
  Future<Either<Failure, bool>> syncAllData() async {
    logger.i('Starting Unified Synchronization process...');
    final stopwatch = Stopwatch()..start();

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Sync Drugs
      logger.i('Syncing Drugs...');
      final lastDrugSync = prefs.getInt('drugs_last_sync_timestamp') ?? 0;
      final drugResult = await drugRepository.getDeltaSyncDrugs(lastDrugSync);

      if (drugResult.isLeft()) {
        drugResult.fold((f) => logger.e('Drug sync failed', f), (_) {});
      }

      // 2. Sync Interactions
      logger.i('Syncing Interactions...');
      final lastIntSync = prefs.getInt('interactions_last_sync_timestamp') ?? 0;
      final interactionResult = await interactionRepository.syncInteractions(
        lastIntSync,
      );
      if (interactionResult.isLeft()) {
        interactionResult.fold(
          (f) => logger.e('Interaction sync failed', f),
          (_) {},
        );
      }

      // 3. Sync Med-Ingredients
      logger.i('Syncing Med-Ingredients...');
      final lastIngSync = prefs.getInt('ingredients_last_sync_timestamp') ?? 0;
      final ingredientsResult = await interactionRepository.syncMedIngredients(
        lastIngSync,
      );
      if (ingredientsResult.isLeft()) {
        ingredientsResult.fold(
          (f) => logger.e('Med-Ingredients sync failed', f),
          (_) {},
        );
      }

      // 4. Sync Dosages
      logger.i('Syncing Dosages...');
      final lastDosSync = prefs.getInt('dosages_last_sync_timestamp') ?? 0;
      final dosageResult = await interactionRepository.syncDosages(lastDosSync);
      if (dosageResult.isLeft()) {
        dosageResult.fold((f) => logger.e('Dosage sync failed', f), (_) {});
      }

      stopwatch.stop();
      logger.i('Unified Sync completed in ${stopwatch.elapsedMilliseconds}ms');

      return const Right(true);
    } catch (e, s) {
      logger.e('Critical error during Unified Sync', e, s);
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
