import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Enhanced Search Bar with mic button and focus ring
/// Matches design-refresh/src/components/layout/SearchBar.tsx
class EnhancedSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onMicTap;
  final VoidCallback? onFilterTap;
  final bool showMic;
  final bool showFilter;

  const EnhancedSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onTap,
    this.onMicTap,
    this.onFilterTap,
    this.showMic = true,
    this.showFilter = false,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _isFocused
                  ? colorScheme.primary
                  : colorScheme.outline.withOpacity(0.2),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow:
            _isFocused
                ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.1),
                    blurRadius: 16,
                    spreadRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(
              LucideIcons.search,
              color:
                  _isFocused
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
          ),

          // Text Field
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              onTap: widget.onTap,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search for drugs...',
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Mic Button
          if (widget.showMic)
            IconButton(
              onPressed: widget.onMicTap ?? () {},
              icon: Icon(
                LucideIcons.mic,
                size: 20,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              tooltip: 'Voice search',
            ),

          // Filter Button
          if (widget.showFilter)
            IconButton(
              onPressed: widget.onFilterTap ?? () {},
              icon: Icon(
                LucideIcons.sliders,
                size: 20,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              tooltip: 'Filters',
            ),

          // Spacing
          if (!widget.showMic && !widget.showFilter) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
