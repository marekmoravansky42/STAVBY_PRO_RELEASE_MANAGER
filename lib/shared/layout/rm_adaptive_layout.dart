import 'package:flutter/material.dart';

/// Semantic window sizes used by the desktop interface.
enum RMWindowClass { compact, medium, expanded, wide }

/// Shared breakpoints for Release Manager desktop layouts.
abstract final class RMAdaptiveBreakpoints {
  static const double medium = 620;
  static const double expanded = 980;
  static const double wide = 1380;

  static RMWindowClass windowClassFor(double width) {
    if (width >= wide) return RMWindowClass.wide;
    if (width >= expanded) return RMWindowClass.expanded;
    if (width >= medium) return RMWindowClass.medium;
    return RMWindowClass.compact;
  }

  static int columnsFor(
    double width, {
    int compact = 1,
    int medium = 2,
    int expanded = 3,
    int wide = 4,
  }) {
    switch (windowClassFor(width)) {
      case RMWindowClass.compact:
        return compact;
      case RMWindowClass.medium:
        return medium;
      case RMWindowClass.expanded:
        return expanded;
      case RMWindowClass.wide:
        return wide;
    }
  }
}

/// Responsive grid that keeps card widths consistent across workspaces.
class RMAdaptiveGrid extends StatelessWidget {
  const RMAdaptiveGrid({
    super.key,
    required this.children,
    this.compactColumns = 1,
    this.mediumColumns = 2,
    this.expandedColumns = 3,
    this.wideColumns = 4,
    this.spacing = 8,
    this.runSpacing,
    this.itemHeight,
  });

  final List<Widget> children;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;
  final int wideColumns;
  final double spacing;
  final double? runSpacing;
  final double? itemHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = RMAdaptiveBreakpoints.columnsFor(
          constraints.maxWidth,
          compact: compactColumns,
          medium: mediumColumns,
          expanded: expandedColumns,
          wide: wideColumns,
        ).clamp(1, children.isEmpty ? 1 : children.length);
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing ?? spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
