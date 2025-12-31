import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class QuickStatsBanner extends StatelessWidget {
  final int totalDrugs;
  final int todayUpdates;
  final int priceIncreases;
  final int priceDecreases;

  const QuickStatsBanner({
    super.key,
    required this.totalDrugs,
    required this.todayUpdates,
    this.priceIncreases = 0,
    this.priceDecreases = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Variables removed as they were unused

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer, // Cleaner solid background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Total drugs stat
          Expanded(
            child: _buildStatItem(
              context,
              icon: LucideIcons.pill,
              label: 'الأدوية',
              value: _formatNumber(totalDrugs),
              color: colorScheme.primary,
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withOpacity(0.3),
          ),

          // Today updates stat
          Expanded(
            child: _buildStatItem(
              context,
              icon: LucideIcons.refreshCw,
              label: 'اليوم',
              value: _formatNumber(todayUpdates),
              color: Colors.blue.shade600,
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withOpacity(0.3),
          ),

          // Price increases stat
          Expanded(
            child: _buildStatItem(
              context,
              icon: LucideIcons.trendingUp,
              label: 'ارتفاع',
              value: _formatNumber(priceIncreases),
              color: Colors.red.shade600,
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withOpacity(0.3),
          ),

          // Price decreases stat
          Expanded(
            child: _buildStatItem(
              context,
              icon: LucideIcons.trendingDown,
              label: 'انخفاض',
              value: _formatNumber(priceDecreases),
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      final thousands = number / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}k';
    }
    return number.toString();
  }
}
