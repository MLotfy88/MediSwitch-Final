import 'package:flutter/material.dart';
import 'package:mediswitch/core/constants/design_tokens.dart';
import 'package:mediswitch/core/utils/animation_helpers.dart';
import 'package:mediswitch/presentation/theme/app_colors_extension.dart';
import 'package:mediswitch/domain/entities/category_entity.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CategoryCard extends StatefulWidget {
  final CategoryEntity category;
  final bool isRTL;

  const CategoryCard({super.key, required this.category, required this.isRTL});

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  IconData _getIconData(String? iconName) {
    if (iconName == null) return LucideIcons.pill;
    switch (iconName.toLowerCase()) {
      case 'heart':
        return LucideIcons.heart;
      case 'brain':
        return LucideIcons.brain;
      case 'smile':
        return LucideIcons.smile;
      case 'baby':
        return LucideIcons.baby;
      case 'eye':
        return LucideIcons.eye;
      case 'bone':
        return LucideIcons.bone;
      default:
        return LucideIcons.pill;
    }
  }

  Color _parseColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'teal':
        return Colors.teal;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.blue; // Default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = false;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {
        // TODO: Navigate to category results
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 100,
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: AppRadius.circularLg,
            border: Border.all(
              color:
                  isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      widget.category.color != null
                          ? _parseColor(widget.category.color!).withOpacity(0.1)
                          : theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconData(widget.category.icon),
                  color:
                      widget.category.color != null
                          ? _parseColor(widget.category.color!)
                          : theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              // Category Name
              Text(
                widget.isRTL ? widget.category.nameAr : widget.category.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              // Item Count
              Text(
                '${widget.category.drugCount} ${widget.isRTL ? 'دواء' : 'Drugs'}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
