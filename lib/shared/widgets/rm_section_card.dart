import 'package:flutter/material.dart';

import '../../design_system.dart';

/// Unified section container used by all primary workspaces.
class RMSectionCard extends StatelessWidget {
  const RMSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.icon = Icons.layers_rounded,
    this.trailing,
  });

  final String title;
  final Widget child;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          RMSectionHeader(title: title, icon: icon, trailing: trailing),
          Padding(padding: RMDesign.cardPadding, child: child),
        ],
      ),
    );
  }
}

class RMSectionHeader extends StatelessWidget {
  const RMSectionHeader({
    super.key,
    required this.title,
    this.icon = Icons.layers_rounded,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: RMDesign.sectionHeaderPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            scheme.primaryContainer.withValues(alpha: 0.68),
            scheme.surface,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: RMDesign.iconBoxSize,
            height: RMDesign.iconBoxSize,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RMDesign.controlRadius),
            ),
            child: Icon(icon, color: scheme.primary, size: 18),
          ),
          const SizedBox(width: RMDesign.space12),
          Expanded(
            child: Tooltip(
              message: title,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
