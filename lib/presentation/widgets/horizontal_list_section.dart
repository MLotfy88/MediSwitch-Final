import 'package:flutter/material.dart';
import 'section_header.dart'; // Assuming SectionHeader exists

class HorizontalListSection extends StatelessWidget {
  final String? title; // Make title optional
  final List<Widget> children;
  final double? listHeight;
  final VoidCallback? onViewAll;
  final EdgeInsetsGeometry listPadding;
  final IconData? icon; // Add icon parameter

  const HorizontalListSection({
    super.key,
    required this.title,
    required this.children,
    this.listHeight,
    this.onViewAll,
    this.listPadding = const EdgeInsets.only(
      left: 16.0,
      right: 16.0,
      bottom: 16.0,
    ),
    this.icon, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 24.0,
              bottom: 16.0,
            ),
            child: SectionHeader(
              title: title!,
              subtitle: "", // Or provide a way to pass subtitle
              icon: Icon(
                icon ?? Icons.category,
              ), // Wrap IconData in helper or Widget
              onMoreTap: onViewAll,
            ),
          ),
        // Horizontal List
        Expanded(child: _buildHorizontalList()),
      ],
    );
  }

  // Helper method to build the horizontal list conditionally
  Widget _buildHorizontalList() {
    if (listHeight != null) {
      // If height is provided, wrap in SizedBox
      return SizedBox(
        height: listHeight,
        child: ListView.separated(
          padding: listPadding,
          scrollDirection: Axis.horizontal,
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
          separatorBuilder:
              (context, index) => const SizedBox(width: 12.0), // gap-3 (12px)
        ),
      );
    } else {
      // If height is null, let the ListView determine its height
      // It should expand vertically within the Column (which gets height from parent SizedBox in HomeScreen)
      return ListView.separated(
        padding: listPadding,
        scrollDirection: Axis.horizontal,
        // shrinkWrap: true, // REMOVED - Let it expand within the fixed height parent
        // physics: const ClampingScrollPhysics(), // REMOVED - Default physics should be fine
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
        separatorBuilder:
            (context, index) => const SizedBox(width: 12.0), // gap-3 (12px)
      );
    }
  }
}
