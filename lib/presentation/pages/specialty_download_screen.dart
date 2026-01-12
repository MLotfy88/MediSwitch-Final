import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mediswitch/domain/entities/medical_specialty.dart';
import 'package:mediswitch/presentation/theme/app_colors.dart';

/// Screen for downloading specialty-specific data
class SpecialtyDownloadScreen extends StatefulWidget {
  const SpecialtyDownloadScreen({super.key});

  @override
  State<SpecialtyDownloadScreen> createState() =>
      _SpecialtyDownloadScreenState();
}

class _SpecialtyDownloadScreenState extends State<SpecialtyDownloadScreen> {
  final Map<String, DownloadStatus> _downloadStatus = {};
  final Map<String, double> _downloadProgress = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isRTL ? 'تحميل بيانات التخصص' : 'Download Specialty Data',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.download,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRTL
                            ? 'تحميل انتقائي للبيانات'
                            : 'Selective Data Download',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRTL
                            ? 'حمّل فقط البيانات المتعلقة بتخصصك الطبي'
                            : 'Download only data relevant to your specialty',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Specialty Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: MedicalSpecialty.all.length,
              itemBuilder: (context, index) {
                final specialty = MedicalSpecialty.all[index];
                return _SpecialtyCard(
                  specialty: specialty,
                  isRTL: isRTL,
                  status: _downloadStatus[specialty.id] ?? DownloadStatus.idle,
                  progress: _downloadProgress[specialty.id] ?? 0.0,
                  onDownload: () => _handleDownload(specialty),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownload(MedicalSpecialty specialty) async {
    setState(() {
      _downloadStatus[specialty.id] = DownloadStatus.downloading;
      _downloadProgress[specialty.id] = 0.0;
    });

    try {
      // TODO: Implement actual download logic
      // This will call the API and save data locally

      // Simulate download progress
      for (var i = 0; i <= 100; i += 10) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() {
            _downloadProgress[specialty.id] = i / 100;
          });
        }
      }

      if (mounted) {
        setState(() {
          _downloadStatus[specialty.id] = DownloadStatus.completed;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded ${specialty.nameEn} data successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloadStatus[specialty.id] = DownloadStatus.failed;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download ${specialty.nameEn} data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

enum DownloadStatus { idle, downloading, completed, failed }

class _SpecialtyCard extends StatelessWidget {
  final MedicalSpecialty specialty;
  final bool isRTL;
  final DownloadStatus status;
  final double progress;
  final VoidCallback onDownload;

  const _SpecialtyCard({
    required this.specialty,
    required this.isRTL,
    required this.status,
    required this.progress,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: specialty.color.withOpacity(0.2), width: 1.5),
      ),
      child: InkWell(
        onTap: status == DownloadStatus.idle ? onDownload : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: specialty.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(specialty.icon, color: specialty.color, size: 32),
              ),

              // Name
              Column(
                children: [
                  Text(
                    isRTL ? specialty.nameAr : specialty.nameEn,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: specialty.color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '~${_estimateSize()} MB',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),

              // Download Button/Status
              _buildActionWidget(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionWidget(ThemeData theme) {
    switch (status) {
      case DownloadStatus.idle:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: specialty.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.download, size: 14, color: specialty.color),
              const SizedBox(width: 6),
              Text(
                isRTL ? 'تحميل' : 'Download',
                style: TextStyle(
                  color: specialty.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      case DownloadStatus.downloading:
        return Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: specialty.color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(specialty.color),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: specialty.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );

      case DownloadStatus.completed:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                isRTL ? 'تم التحميل' : 'Downloaded',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );

      case DownloadStatus.failed:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.xCircle, size: 14, color: Colors.red),
              const SizedBox(width: 6),
              Text(
                isRTL ? 'فشل' : 'Failed',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
    }
  }

  String _estimateSize() {
    // Rough estimate: 15-30MB per specialty
    return '15-30';
  }
}
