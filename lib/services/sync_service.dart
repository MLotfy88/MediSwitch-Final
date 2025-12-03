import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import '../services/database_service.dart';

/// Service for syncing drug data with Cloudflare Worker Backend
class SyncService {
  // Cloudflare Worker configuration
  // TODO: Replace with your actual Cloudflare Worker URL after deployment
  static const String BASE_URL = 'https://mediswitch-api.m-m-lotfy-88.workers.dev/';
  static const String SYNC_ENDPOINT = '/api/sync';
  
  // SharedPreferences keys
  static const String LAST_SYNC_KEY = 'last_sync_date';
  static const String SYNC_COUNT_KEY = 'sync_count';
  
  final DatabaseService _db = DatabaseService();
  
  /// Check if sync is needed (last sync was more than 24 hours ago)
  Future<bool> needsSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(LAST_SYNC_KEY);
    
    if (lastSyncStr == null) return true;
    
    try {
      final lastSync = DateTime.parse(lastSyncStr);
      final now = DateTime.now();
      final difference = now.difference(lastSync);
      
      // Sync if more than 24 hours have passed
      return difference.inHours >= 24;
    } catch (e) {
      return true;
    }
  }
  
  /// Get last sync date
  Future<DateTime?> getLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(LAST_SYNC_KEY);
    
    if (lastSyncStr == null) return null;
    
    try {
      return DateTime.parse(lastSyncStr);
    } catch (e) {
      return null;
    }
  }
  
  /// Save last sync date
  Future<void> _saveLastSyncDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LAST_SYNC_KEY, date.toIso8601String());
  }
  
  /// Increment sync count
  Future<void> _incrementSyncCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(SYNC_COUNT_KEY) ?? 0;
    await prefs.setInt(SYNC_COUNT_KEY, count + 1);
  }
  
  /// Perform incremental sync with backend
  Future<SyncResult> sync() async {
    try {
      // Get last sync date
      final lastSync = await getLastSyncDate();
      
      // If never synced, use a very old date
      final sinceDate = lastSync ?? DateTime(2020, 1, 1);
      final sinceDateStr = _formatDate(sinceDate);
      
      // Build URL
      final url = Uri.parse('$BASE_URL$SYNC_ENDPOINT?since=$sinceDateStr');
      
      print('🔄 Syncing with backend: $url');
      
      // Make request
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode != 200) {
        throw Exception('Sync failed: ${response.statusCode}');
      }
      
      // Parse response
      final data = json.decode(response.body);
      final drugsJson = data['drugs'] as List<dynamic>;
      final count = data['count'] as int;
      
      print('📦 Received $count drugs from backend');
      
      // Update local database
      int updated = 0;
      int inserted = 0;
      
      for (var drugJson in drugsJson) {
        final isNew = await _upsertDrug(drugJson);
        if (isNew) {
          inserted++;
        } else {
          updated++;
        }
      }
      
      // Save sync date
      await _saveLastSyncDate(DateTime.now());
      await _incrementSyncCount();
      
      print('✅ Sync complete: $inserted new, $updated updated');
      
      return SyncResult(
        success: true,
        newDrugs: inserted,
        updatedDrugs: updated,
        totalSynced: count,
      );
      
    } catch (e) {
      print('❌ Sync error: $e');
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Upsert a single drug into local database
  Future<bool> _upsertDrug(Map<String, dynamic> drugJson) async {
    try {
      // Check if drug exists (by trade name)
      final tradeName = drugJson['trade_name'] as String;
      final existing = await _db.searchMedicines(tradeName);
      
      // Create Medicine object
      final medicine = Medicine(
        tradeName: drugJson['trade_name'] ?? '',
        arabicName: drugJson['arabic_name'] ?? '',
        oldPrice: _parsePrice(drugJson['old_price']),
        price: _parsePrice(drugJson['price']),
        active: drugJson['active_ingredients'] ?? '',
        mainCategory: drugJson['main_category'] ?? '',
        mainCategoryAr: drugJson['main_category_ar'] ?? '',
        category: drugJson['category'] ?? '',
        categoryAr: drugJson['category_ar'] ?? '',
        company: drugJson['company'] ?? '',
        dosageForm: drugJson['dosage_form'] ?? '',
        dosageFormAr: drugJson['dosage_form_ar'] ?? '',
        unit: drugJson['unit'] ?? '1',
        usage: drugJson['usage'] ?? '',
        usageAr: drugJson['usage_ar'] ?? '',
        description: drugJson['description'] ?? '',
        lastPriceUpdate: drugJson['last_price_update'] ?? '',
        concentration: drugJson['concentration'] ?? '',
      );
      
      if (existing.isEmpty) {
        // Insert new
        await _db.insertMedicine(medicine);
        return true;
      } else {
        // Update existing
        await _db.updateMedicine(medicine);
        return false;
      }
      
    } catch (e) {
      print('Error upserting drug: $e');
      return false;
    }
  }
  
  /// Parse price from various formats
  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    }
    return 0.0;
  }
  
  /// Format date to dd/mm/yyyy
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int newDrugs;
  final int updatedDrugs;
  final int totalSynced;
  final String? error;
  
  SyncResult({
    required this.success,
    this.newDrugs = 0,
    this.updatedDrugs = 0,
    this.totalSynced = 0,
    this.error,
  });
  
  @override
  String toString() {
    if (!success) {
      return 'Sync failed: $error';
    }
    return 'Sync successful: $newDrugs new, $updatedDrugs updated ($totalSynced total)';
  }
}
