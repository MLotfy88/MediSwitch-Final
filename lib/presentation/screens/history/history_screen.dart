import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/animation_helpers.dart';

/// History Screen - shows search history
/// Matches design-refresh/src/components/screens/HistoryScreen.tsx
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Mock history data
  final List<HistoryItem> _history = [
    HistoryItem(
      id: '1',
      query: 'Panadol',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    HistoryItem(
      id: '2',
      query: 'Augmentin',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    HistoryItem(
      id: '3',
      query: 'Concor',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    HistoryItem(
      id: '4',
      query: 'Aspirin',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  void _deleteItem(String id) {
    setState(() {
      _history.removeWhere((item) => item.id == id);
    });
  }

  void _clearAll() {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              Directionality.of(context) == ui.TextDirection.rtl
                  ? 'مسح السجل'
                  : 'Clear History',
            ),
            content: Text(
              Directionality.of(context) == ui.TextDirection.rtl
                  ? 'هل تريد مسح جميع سجل البحث؟'
                  : 'Are you sure you want to clear all search history?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  Directionality.of(context) == ui.TextDirection.rtl
                      ? 'إلغاء'
                      : 'Cancel',
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _history.clear());
                  Navigator.pop(context);
                },
                child: Text(
                  Directionality.of(context) == ui.TextDirection.rtl
                      ? 'مسح'
                      : 'Clear',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
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

                    // Title
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
                                ? '${_history.length} عملية بحث'
                                : '${_history.length} searches',
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
                    if (_history.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearAll,
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: colorScheme.error,
                        ),
                        label: Text(
                          isRTL ? 'مسح الكل' : 'Clear All',
                          style: TextStyle(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
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
                _history.isEmpty
                    ? _buildEmptyState(context, isRTL, colorScheme)
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return FadeSlideAnimation(
                          delay: StaggeredAnimationHelper.delayFor(index),
                          child: _buildHistoryItem(
                            context,
                            item,
                            isRTL,
                            colorScheme,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    HistoryItem item,
    bool isRTL,
    ColorScheme colorScheme,
  ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item.id),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to search with this query
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Clock Icon
                Icon(
                  LucideIcons.clock,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),

                // Query Text
                Expanded(
                  child: Text(
                    item.query,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Timestamp
                Text(
                  _formatTimestamp(item.timestamp, isRTL),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),

                // Arrow Icon
                Icon(
                  isRTL ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
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
                  ? 'سيظهر سجل البحث هنا'
                  : 'Your search history will appear here',
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
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return isRTL
          ? 'منذ ${difference.inMinutes} دقيقة'
          : '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return isRTL
          ? 'منذ ${difference.inHours} ساعة'
          : '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return isRTL
          ? 'منذ ${difference.inDays} يوم'
          : '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}

class HistoryItem {
  final String id;
  final String query;
  final DateTime timestamp;

  HistoryItem({required this.id, required this.query, required this.timestamp});
}
