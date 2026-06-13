import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool selected;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.selected = false,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final decoration = tokens.cardDecoration(elevated: elevated).copyWith(
          border: Border.all(
            color: selected ? tokens.accent : tokens.border.withValues(alpha: 0.7),
            width: selected ? 1.5 : 1,
          ),
        );

    final content = AnimatedContainer(
      duration: DesignTokens.durationNormal,
      curve: DesignTokens.curveStandard,
      padding: padding ?? const EdgeInsets.all(DesignTokens.spacing16),
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
        child: content,
      ),
    );
  }
}
