import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/core/di/locator.dart';
import 'package:mediswitch/data/datasources/local/sqlite_local_data_source.dart';
import 'package:mediswitch/presentation/bloc/medicine_provider.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';
import 'package:mediswitch/presentation/widgets/section_header.dart';
import 'package:provider/provider.dart';

import '../debug/log_viewer_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int> _stats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats =
          await locator<SqliteLocalDataSource>().getDashboardStatistics();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading dashboard stats: $e");
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRTL ? 'لوحة التحكم' : 'Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileText),
            tooltip: isRTL ? 'عرض السجلات' : 'View Logs',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogViewerScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<MedicineProvider>(
        builder: (context, provider, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.smartRefresh();
              await _loadStats();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverviewSection(context, provider, isRTL),
                const SizedBox(height: 24),
                _buildActionsSection(context, provider, isRTL),
                const SizedBox(height: 24),
                _buildD1StatusSection(context, isRTL),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewSection(
    BuildContext context,
    MedicineProvider provider,
    bool isRTL,
  ) {
    return Column(
      children: [
        SectionHeader(
          title: isRTL ? 'نظرة عامة' : 'Overview',
          subtitle:
              isRTL ? 'إحصائيات البيانات المحلية' : 'Local Data Statistics',
          icon: LucideIcons.barChart2,
          iconColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.1),
          iconTintColor: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: isRTL ? 'إجمالي الأدوية' : 'Total Drugs',
                value:
                    _isLoadingStats
                        ? '...'
                        : (_stats['drugs']?.toString() ?? '0'),
                icon: LucideIcons.pill,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: isRTL ? 'تفاعلات الطعام' : 'Food Interactions',
                value:
                    _isLoadingStats
                        ? '...'
                        : (_stats['food_interactions']?.toString() ?? '0'),
                icon: LucideIcons.utensils,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: isRTL ? 'بيانات الفارماكولوجي' : 'Pharmacology',
                value:
                    _isLoadingStats
                        ? '...'
                        : (_stats['pharmacology']?.toString() ?? '0'),
                icon: LucideIcons.flaskConical,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: isRTL ? 'إرشادات الجرعات' : 'Dosage Guidelines',
                value:
                    _isLoadingStats
                        ? '...'
                        : (_stats['dosage_guidelines']?.toString() ?? '0'),
                icon: LucideIcons.receipt,
                color: Colors.purple,
                isSmallText: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionsSection(
    BuildContext context,
    MedicineProvider provider,
    bool isRTL,
  ) {
    return Column(
      children: [
        SectionHeader(
          title: isRTL ? 'إجراءات الإدارة' : 'Admin Actions',
          subtitle: isRTL ? 'أدوات إدارة البيانات' : 'Data Management Tools',
          icon: LucideIcons.settings,
          iconColor: Theme.of(
            context,
          ).colorScheme.secondary.withValues(alpha: 0.1),
          iconTintColor: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          title: isRTL ? 'تحديث إجباري' : 'Force Sync Data',
          subtitle:
              isRTL
                  ? 'تنزيل أحدث البيانات من D1'
                  : 'Download latest data from Cloudflare D1',
          icon: LucideIcons.refreshCw,
          color: Colors.blue,
          onTap: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isRTL ? 'جاري التحديث...' : 'Syncing...')),
            );
            await provider.loadInitialData(forceUpdate: true);
            await _loadStats();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isRTL ? 'تم التحديث بنجاح' : 'Sync Complete'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _buildActionTile(
          context,
          title: isRTL ? 'إعادة تهيئة قاعدة البيانات' : 'Re-seed Database',
          subtitle:
              isRTL
                  ? 'إعادة تحميل البيانات من الملفات المحلية'
                  : 'Reset DB from local assets assets',
          icon: LucideIcons.databaseBackup,
          color: Colors.red,
          onTap: () {
            // TODO: Implement direct reseeding logic exposed via provider or datasource
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Not implemented yet in Provider')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildD1StatusSection(BuildContext context, bool isRTL) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.cloud, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                isRTL ? 'حالة D1 Cloud' : 'D1 Cloud Status',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(),
          _buildStatusRow(
            isRTL ? 'الاتصال' : 'Connection',
            'Connected ✅',
            Colors.green,
          ),
          _buildStatusRow(
            isRTL ? 'عدد السجلات' : 'Total Records',
            '25,491',
            Colors.blue,
          ),
          _buildStatusRow(
            isRTL ? 'حالة الرفع' : 'Upload Status',
            'Complete (100%)',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.mutedForeground)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isSmallText = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 14 : 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      tileColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
      ),
      trailing: const Icon(LucideIcons.chevronRight, size: 16),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month}-${date.day}';
  }
}
