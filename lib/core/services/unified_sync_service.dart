import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:mediswitch/core/error/failures.dart';
import 'package:mediswitch/core/services/file_logger_service.dart';
import 'package:mediswitch/domain/repositories/drug_repository.dart';
import 'package:mediswitch/domain/repositories/interaction_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service responsible for orchestrating synchronization across multiple repositories.
class UnifiedSyncService {
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

      // 0. Sync Notifications (Background check)
      await _syncNotifications(prefs);

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

      // 5. Sync Food Interactions
      logger.i('Syncing Food Interactions...');
      final lastFoodSync =
          prefs.getInt('food_interactions_last_sync_timestamp') ?? 0;
      final foodResult = await interactionRepository.syncFoodInteractions(
        lastFoodSync,
      );
      if (foodResult.isLeft()) {
        foodResult.fold(
          (f) => logger.e('Food interaction sync failed', f),
          (_) {},
        );
      }

      // 6. Sync Disease Interactions
      logger.i('Syncing Disease Interactions...');
      final lastDiseaseSync =
          prefs.getInt('disease_interactions_last_sync_timestamp') ?? 0;
      final diseaseResult = await interactionRepository.syncDiseaseInteractions(
        lastDiseaseSync,
      );
      if (diseaseResult.isLeft()) {
        diseaseResult.fold(
          (f) => logger.e('Disease interaction sync failed', f),
          (_) {},
        );
      }

      stopwatch.stop();
      logger.i('Unified Sync completed in ${stopwatch.elapsedMilliseconds}ms');

      return const Right(true);
    } on Exception catch (e, s) {
      logger.e('Critical error during Unified Sync', e, s);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<void> _syncNotifications(SharedPreferences prefs) async {
    try {
      logger.i('Syncing Notifications...');
      // Use proper URL constant if available, otherwise hardcode for background reliability
      final uri = Uri.parse(
        'https://mediswitch-api.m-m-lotfy-88.workers.dev/api/admin/notifications?limit=10',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> data = (body['data'] as List<dynamic>?) ?? [];

        final existingJson = prefs.getString('app_notifications');
        var existingList = <dynamic>[];
        if (existingJson != null) {
          try {
            final decoded = jsonDecode(existingJson);
            if (decoded is List) {
              existingList = List<dynamic>.from(decoded);
            }
          } on Exception catch (_) {}
        }

        bool changed = false;

        for (final item in data) {
          if (item is! Map<String, dynamic>) continue;
          if (item['id'] == null) continue;

          final String remoteId = item['id'].toString();
          final String localId = 'remote_$remoteId';

          final bool alreadyExists = existingList.any((e) {
            if (e is Map<String, dynamic>) {
              return e['id'] == localId;
            }
            return false;
          });

          if (alreadyExists) continue;

          final Map<String, dynamic> newNotif = {
            'id': localId,
            'title': (item['title'] as String?) ?? 'Notification',
            'titleAr': (item['title'] as String?) ?? 'Notification',
            'message': (item['message'] as String?) ?? '',
            'messageAr': (item['message'] as String?) ?? '',
            'type': (item['type'] as String?) ?? 'info',
            'timestamp':
                item['created_at'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                      (item['created_at'] as int) * 1000,
                    ).toIso8601String()
                    : DateTime.now().toIso8601String(),
            'isRead': false,
            'metadata': item['metadata'],
          };

          existingList.insert(0, newNotif);
          changed = true;

          await _showBackgroundNotification(
            newNotif['title'] as String,
            newNotif['message'] as String,
          );
        }

        if (changed) {
          await prefs.setString('app_notifications', jsonEncode(existingList));
          logger.i('Notifications synced and saved.');
        }
      }
    } on Exception catch (e) {
      logger.e('Notification sync error', e);
    }
  }

  Future<void> _showBackgroundNotification(String title, String body) async {
    try {
      final fln = FlutterLocalNotificationsPlugin();
      // Initialize for Android (required even if redundant)
      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_stat_notification',
      );
      const initSettings = InitializationSettings(android: androidSettings);
      await fln.initialize(initSettings);

      const androidDetails = AndroidNotificationDetails(
        'mediswitch_updates',
        'MediSwitch Updates',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);
      await fln.show(DateTime.now().millisecond, title, body, details);
    } on Exception catch (e) {
      logger.e('Failed to show background notification', e);
    }
  }
}
