import 'package:flutter/material.dart';
import 'section_header.dart'; // Reuse the SectionHeader

class HorizontalListSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onViewAll;
  final double listHeight; // Height required for the horizontal list
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry listPadding;

  const HorizontalListSection({
    super.key,
    required this.title,
    required this.children,
    this.onViewAll,
    required this.listHeight,
    this.headerPadding = const EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: 8,
    ),
    this.listPadding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Important for use in ListView
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Use the existing SectionHeader for title and action
        SectionHeader(
          title: title,
          padding: headerPadding,
          action:
              onViewAll != null
                  ? TextButton.icon(
                    // Use TextButton.icon for text + icon
                    onPressed: onViewAll,
                    icon: const Icon(
                      Icons.chevron_right,
                      size: 20,
                    ), // Use appropriate icon for RTL
                    label: const Text('عرض الكل'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      // Match text style from design if needed
                      // textStyle: TextStyle(fontWeight: FontWeight.w600),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  )
                  : null,
        ),
        SizedBox(
          height: listHeight,
          child: ListView.separated(
            padding: listPadding,
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder:
                (context, index) =>
                    const SizedBox(width: 12.0), // Adjust spacing
            itemBuilder: (context, index) {
              return children[index];
            },
          ),
        ),
      ],
    );
  }
}
