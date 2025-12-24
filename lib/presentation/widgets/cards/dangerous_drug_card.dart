import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors_extension.dart';

enum RiskLevel { critical, high }

class DangerousDrugCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final RiskLevel riskLevel;
  final int interactionCount;
  final VoidCallback? onTap;

  const DangerousDrugCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.riskLevel,
    required this.interactionCount,
    this.onTap,
  });

  @override
  State<DangerousDrugCard> createState() => _DangerousDrugCardState();
}

class _DangerousDrugCardState extends State<DangerousDrugCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) _controller.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    final isCritical = widget.riskLevel == RiskLevel.critical;

    final backgroundColor =
        isCritical
            ? appColors.danger.withOpacity(0.08)
            : appColors.warning.withOpacity(0.08);

    final borderColor =
        isCritical
            ? appColors.danger.withOpacity(0.2)
            : appColors.warning.withOpacity(0.2);

    final iconBg =
        isCritical
            ? appColors.danger.withOpacity(0.15)
            : appColors.warning.withOpacity(0.15);

    final iconColor = isCritical ? appColors.danger : appColors.warning;

    final iconData = isCritical ? LucideIcons.skull : LucideIcons.alertTriangle;

    final textColor = isCritical ? appColors.danger : appColors.warning;

    final badgeBg =
        isCritical
            ? appColors.danger.withOpacity(0.12)
            : appColors.warning.withOpacity(0.12);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: (isCritical ? appColors.danger : appColors.warning)
                        .withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Large Warning Icon Container
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(iconData, size: 28, color: iconColor),
                    ),

                    const SizedBox(width: 16),

                    // Content Area
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: appColors.mutedForeground,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Premium Horizontal Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.alertTriangle,
                                  size: 12,
                                  color: iconColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isRTL
                                      ? '${widget.interactionCount} تفاعلات'
                                      : '${widget.interactionCount} interactions',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Arrow
                    Icon(
                      isRTL
                          ? LucideIcons.chevronLeft
                          : LucideIcons.chevronRight,
                      size: 20,
                      color: appColors.mutedForeground.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
