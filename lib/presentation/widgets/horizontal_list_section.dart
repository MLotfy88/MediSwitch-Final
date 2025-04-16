import 'package:flutter/material.dart';
import 'section_header.dart'; // Assuming SectionHeader exists

class HorizontalListSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double listHeight;
  final VoidCallback? onViewAll;
  // Remove headerPadding, control padding within this widget
  // final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry listPadding;

  const HorizontalListSection({
    super.key,
    required this.title,
    required this.children,
    required this.listHeight,
    this.onViewAll,
    // Remove headerPadding from constructor
    this.listPadding = const EdgeInsets.only(
      left: 16.0,
      right: 16.0,
      bottom: 16.0,
    ), // Add bottom padding to list
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink(); // Don't show section if no children
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with specific padding matching design doc (mb-4 -> bottom: 16.0)
        Padding(
          // Apply standard horizontal padding and specific bottom margin
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 24.0,
            bottom: 16.0,
          ), // Added top padding for consistency
          child: SectionHeader(
            title: title,
            onViewAll: onViewAll,
            padding:
                EdgeInsets
                    .zero, // Remove default padding from SectionHeader itself
          ),
        ),
        // Horizontal List
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            padding: listPadding, // Use listPadding for the ListView
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
            separatorBuilder:
                (context, index) => const SizedBox(width: 12.0), // gap-3 (12px)
          ),
        ),
      ],
    );
  }
}
