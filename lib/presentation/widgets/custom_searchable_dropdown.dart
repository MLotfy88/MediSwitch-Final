import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/entities/drug_entity.dart'; // Assuming we search for DrugEntity

// Simple Searchable Dropdown Implementation
// Consider using a package like 'dropdown_search' for more features later

class CustomSearchableDropdown extends StatefulWidget {
  final List<DrugEntity> items;
  final DrugEntity? selectedItem;
  final ValueChanged<DrugEntity?> onChanged;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final String? Function(DrugEntity?)? validator;

  const CustomSearchableDropdown({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
  });

  @override
  State<CustomSearchableDropdown> createState() =>
      _CustomSearchableDropdownState();
}

class _CustomSearchableDropdownState extends State<CustomSearchableDropdown> {
  final TextEditingController _searchController = TextEditingController();
  List<DrugEntity> _filteredItems = [];
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_onSearchChanged);
    // Set initial text if an item is pre-selected
    if (widget.selectedItem != null) {
      _searchController.text = widget.selectedItem!.tradeName;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _removeOverlay(); // Ensure overlay is removed on dispose
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems =
          widget.items.where((item) {
            return item.tradeName.toLowerCase().contains(query) ||
                item.arabicName.toLowerCase().contains(query) ||
                item.active.toLowerCase().contains(query);
          }).toList();
    });
    // Update overlay content if visible
    if (_isOverlayVisible) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _toggleOverlay() {
    if (_isOverlayVisible) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(
                0.0,
                size.height + 5.0,
              ), // Position below the field
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height *
                        0.3, // Limit height
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                        title: Text(item.tradeName),
                        subtitle: Text(
                          item.active,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        dense: true,
                        onTap: () {
                          _selectItem(item);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(_overlayEntry!);
    setState(() {
      _isOverlayVisible = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOverlayVisible = false;
    });
  }

  void _selectItem(DrugEntity item) {
    _searchController.removeListener(
      _onSearchChanged,
    ); // Temporarily remove listener
    _searchController.text = item.tradeName; // Update text field
    _searchController.addListener(_onSearchChanged); // Re-add listener
    widget.onChanged(item); // Notify parent widget
    _removeOverlay(); // Close overlay
    FocusScope.of(context).unfocus(); // Hide keyboard
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: Icon(widget.prefixIcon, color: theme.colorScheme.primary),
          suffixIcon: IconButton(
            icon: Icon(
              _isOverlayVisible
                  ? LucideIcons.chevronUp
                  : LucideIcons.chevronDown,
            ),
            onPressed: _toggleOverlay,
            tooltip: _isOverlayVisible ? 'إخفاء الخيارات' : 'إظهار الخيارات',
          ),
          // Use theme's input decoration
        ),
        onTap: () {
          // Show overlay when tapping the field if not already visible
          if (!_isOverlayVisible) {
            _showOverlay();
          }
          // Reset filter when tapping to show all items initially
          setState(() {
            _filteredItems = widget.items;
          });
          _overlayEntry?.markNeedsBuild();
        },
        validator: (value) {
          // Validate based on the *selected* item, not just the text field value
          if (widget.validator != null) {
            return widget.validator!(widget.selectedItem);
          }
          return null;
        },
        // Close overlay if user taps outside
        onTapOutside: (event) {
          if (_isOverlayVisible) {
            _removeOverlay();
          }
        },
      ),
    );
  }
}
