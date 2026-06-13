import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';

class ConfigOption extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;

  const ConfigOption({
    super.key,
    required this.label,
    this.subtitle,
    this.leading,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        curve: DesignTokens.curveStandard,
        padding: const EdgeInsets.all(DesignTokens.spacing12),
        decoration: BoxDecoration(
          color: selected ? tokens.surfaceMuted : tokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
          border: Border.all(
            color: selected ? tokens.accent : tokens.border.withValues(alpha: 0.7),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected && !tokens.isDark ? tokens.cardShadow : null,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: DesignTokens.spacing12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tokens.textStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tokens.textStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedOpacity(
              duration: DesignTokens.durationFast,
              opacity: selected ? 1 : 0,
              child: Icon(Icons.check_circle_rounded, color: tokens.accent, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorSwatchOption extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const ColorSwatchOption({
    super.key,
    required this.color,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: DesignTokens.durationNormal,
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? tokens.accent : tokens.border,
                width: selected ? 2.5 : 1,
              ),
              boxShadow: selected ? tokens.cardShadow : null,
            ),
            child: selected
                ? Icon(Icons.check, color: _contrastIcon(color), size: 22)
                : null,
          ),
          const SizedBox(height: DesignTokens.spacing8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: tokens.textStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _contrastIcon(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
  }
}
