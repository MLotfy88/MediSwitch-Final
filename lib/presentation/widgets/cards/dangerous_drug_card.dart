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

    // Determine styles based on risk level
    final isCritical = widget.riskLevel == RiskLevel.critical;

    // Using exact tailwind-like opacity from React reference
    // React: bg-danger/10 vs warning-soft (usually 20-30%)
    final backgroundColor =
        isCritical
            ? appColors.danger.withOpacity(0.1)
            : appColors.warning.withOpacity(0.1);

    // React: border-danger/30 vs border-warning/30
    final borderColor =
        isCritical
            ? appColors.danger.withOpacity(0.3)
            : appColors.warning.withOpacity(0.3);

    // React: bg-danger/20 vs bg-warning/20
    final iconBg =
        isCritical
            ? appColors.danger.withOpacity(0.2)
            : appColors.warning.withOpacity(0.2);

    final iconColor =
        isCritical
            ? appColors.danger
            : appColors
                .warning; // Use main color not foreground for sharper contrast on light bg

    final iconData = isCritical ? LucideIcons.skull : LucideIcons.alertTriangle;

    final textColor =
        isCritical
            ? appColors.danger
            : appColors.warning; // Match text with icon

    final badgeBg =
        isCritical
            ? appColors.danger.withOpacity(0.2)
            : appColors.warning.withOpacity(0.2);

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
              width: 140, // Fixed width
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon & Header
                  Container(
                    width: isRTL ? double.infinity : 40,
                    alignment:
                        isRTL ? Alignment.centerRight : Alignment.centerLeft,
                    child:
                        isRTL
                            ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Placeholder for potential top-right badge if needed in future
                                const SizedBox(),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    iconData,
                                    size: 20,
                                    color: iconColor,
                                  ),
                                ),
                              ],
                            )
                            : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(iconData, size: 20, color: iconColor),
                            ),
                  ),

                  const SizedBox(height: 10),

                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: appColors.mutedForeground,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Interaction Badge
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment:
                          isRTL
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      children: [
                        if (!isRTL) ...[
                          Icon(
                            LucideIcons.alertTriangle,
                            size: 10,
                            color: iconColor,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            isRTL
                                ? '${widget.interactionCount} تفاعلات'
                                : '${widget.interactionCount} interactions',
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isRTL) ...[
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.alertTriangle,
                            size: 10,
                            color: iconColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
