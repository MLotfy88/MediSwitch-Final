import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/animation_helpers.dart';
import '../../../domain/entities/drug_entity.dart';
import '../../bloc/medicine_provider.dart';
import '../../widgets/drug_card.dart';
import '../details/drug_details_screen.dart';

/// History Screen - shows recently viewed drugs
/// Matches design-refresh/src/components/screens/HistoryScreen.tsx
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Local history storage - in production, use SharedPreferences or database
  final List<ViewedDrug> _viewedDrugs = [];

  @override
  void initState() {
    super.initState();
    _loadRecentlyViewedFromProvider();
  }

  void _loadRecentlyViewedFromProvider() {
    // Use recently viewed drugs from provider
    final provider = context.read<MedicineProvider>();
    final recentDrugs = provider.recentlyViewedDrugs.toList();

    setState(() {
      _viewedDrugs.clear();
      for (int i = 0; i < recentDrugs.length; i++) {
        _viewedDrugs.add(
          ViewedDrug(
            drug: recentDrugs[i],
            viewedAt: DateTime.now().subtract(Duration(hours: i * 2)),
          ),
        );
      }
    });
  }

  void _clearHistory() {
    final l10n = AppLocalizations.of(context)!;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isRTL ? 'مسح السجل' : 'Clear History'),
            content: Text(
              isRTL
                  ? 'هل تريد مسح جميع سجل المشاهدة؟'
                  : 'Are you sure you want to clear all viewing history?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isRTL ? 'إلغاء' : 'Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _viewedDrugs.clear());
                  Navigator.pop(context);
                },
                child: Text(
                  isRTL ? 'مسح' : 'Clear',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }

  void _navigateToDetails(DrugEntity drug) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DrugDetailsScreen(drug: drug)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header - matching reference design
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.95),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.history,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRTL ? 'السجل' : 'History',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isRTL
                                ? 'الأدوية التي تم عرضها مؤخراً'
                                : 'Recently viewed drugs',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Clear All Button
                    if (_viewedDrugs.isNotEmpty)
                      IconButton(
                        onPressed: _clearHistory,
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 20,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // History List
          Expanded(
            child:
                _viewedDrugs.isEmpty
                    ? _buildEmptyState(context, isRTL, colorScheme)
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _viewedDrugs.length,
                      itemBuilder: (context, index) {
                        final item = _viewedDrugs[index];
                        return FadeSlideAnimation(
                          delay: StaggeredAnimationHelper.delayFor(index),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timestamp row
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8,
                                  left: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.clock,
                                      size: 12,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatTimestamp(item.viewedAt, isRTL),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // Drug Card
                              DrugCard(
                                drug: item.drug,
                                type: DrugCardType.detailed,
                                onTap: () => _navigateToDetails(item.drug),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isRTL,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.history,
                size: 40,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isRTL ? 'لا يوجد سجل' : 'No history yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isRTL
                  ? 'الأدوية التي تعرضها ستظهر هنا'
                  : 'Drugs you view will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp, bool isRTL) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final timestampDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    final timeStr = DateFormat('h:mm a').format(timestamp);

    if (timestampDate == today) {
      return isRTL ? 'اليوم، $timeStr' : 'Today, $timeStr';
    } else if (timestampDate == yesterday) {
      return isRTL ? 'أمس، $timeStr' : 'Yesterday, $timeStr';
    } else {
      final dateStr = DateFormat('MMM d').format(timestamp);
      return '$dateStr, $timeStr';
    }
  }
}

class ViewedDrug {
  final DrugEntity drug;
  final DateTime viewedAt;

  ViewedDrug({required this.drug, required this.viewedAt});
}
