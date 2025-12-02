import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Widget to show sync status and trigger manual sync
class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({Key? key}) : super(key: key);

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final SyncService _syncService = SyncService();
  bool _isSyncing = false;
  DateTime? _lastSync;
  String? _syncStatus;
  
  @override
  void initState() {
    super.initState();
    _loadLastSyncDate();
    _autoSync();
  }
  
  Future<void> _loadLastSyncDate() async {
    final lastSync = await _syncService.getLastSyncDate();
    setState(() {
      _lastSync = lastSync;
    });
  }
  
  /// Auto-sync if needed and connected
  Future<void> _autoSync() async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return;
      }
      
      // Check if sync needed
      final needsSync = await _syncService.needsSync();
      if (needsSync) {
        await _performSync();
      }
    } catch (e) {
      print('Auto-sync error: $e');
    }
  }
  
  Future<void> _performSync() async {
    setState(() {
      _isSyncing = true;
      _syncStatus = 'جاري المزامنة...';
    });
    
    try {
      final result = await _syncService.sync();
      
      setState(() {
        _isSyncing = false;
        _lastSync = DateTime.now();
        
        if (result.success) {
          _syncStatus = 'تم تحديث ${result.newDrugs + result.updatedDrugs} دواء';
        } else {
          _syncStatus = 'فشلت المزامنة: ${result.error}';
        }
      });
      
      // Clear status after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _syncStatus = null;
          });
        }
      });
      
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _syncStatus = 'خطأ: $e';
      });
    }
  }
  
  String _formatLastSync() {
    if (_lastSync == null) return 'لم تتم المزامنة بعد';
    
    final now = DateTime.now();
    final difference = now.difference(_lastSync!);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Sync icon
          _isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.cloud_sync,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
          
          const SizedBox(width: 12),
          
          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _syncStatus ?? 'آخر تحديث: ${_formatLastSync()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Manual sync button
          if (!_isSyncing)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _performSync,
              tooltip: 'تحديث يدوي',
            ),
        ],
      ),
    );
  }
}
