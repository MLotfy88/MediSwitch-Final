import 'package:flutter/material.dart';
import 'section_header.dart'; // Assuming SectionHeader exists

class HorizontalListSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double listHeight;
  final VoidCallback? onViewAll;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry listPadding;

  const HorizontalListSection({
    super.key,
    required this.title,
    required this.children,
    required this.listHeight,
    this.onViewAll,
    this.headerPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ),
    this.listPadding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink(); // Don't show section if no children
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: headerPadding,
          child: SectionHeader(
            title: title,
            onViewAll: onViewAll, // Pass the callback
          ),
        ),
        // Horizontal List
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            padding: listPadding,
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
            separatorBuilder:
                (context, index) =>
                    const SizedBox(width: 12.0), // Spacing between items
          ),
        ),
      ],
    );
  }
}
