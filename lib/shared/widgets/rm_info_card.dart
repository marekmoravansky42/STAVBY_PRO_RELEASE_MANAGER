import 'package:flutter/material.dart';

import '../../design_system.dart';

class RMInfoCard extends StatelessWidget {
  const RMInfoCard({super.key, required this.child, this.padding = RMDesign.cardPadding});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(RMDesign.cardRadius),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.55)),
        ),
        child: child,
      );
}
