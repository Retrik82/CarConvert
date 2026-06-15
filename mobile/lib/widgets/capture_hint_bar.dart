import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';

class CaptureHintBar extends StatelessWidget {
  final String message;
  final bool isPerfect;
  final String arrowDirection;
  final bool floating;

  const CaptureHintBar({
    super.key,
    required this.message,
    this.isPerfect = false,
    this.arrowDirection = 'none',
    this.floating = false,
  });

  IconData? get _directionIcon {
    return switch (arrowDirection) {
      'left' => Icons.arrow_back_rounded,
      'right' => Icons.arrow_forward_rounded,
      'up' => Icons.arrow_upward_rounded,
      'down' => Icons.arrow_downward_rounded,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = isPerfect ? const Color(0xFF66BB6A) : Colors.white;
    final directionIcon = _directionIcon;

    return AnimatedContainer(
      duration: DesignTokens.durationNormal,
      curve: DesignTokens.curveStandard,
      padding: EdgeInsets.symmetric(
        horizontal: floating ? DesignTokens.spacing12 : DesignTokens.spacing16,
        vertical: floating ? DesignTokens.spacing8 : DesignTokens.spacing12,
      ),
      decoration: BoxDecoration(
        color: isPerfect
            ? const Color(0xE62E7D32)
            : (floating ? Colors.black.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(floating ? DesignTokens.radiusChip : DesignTokens.radiusInput),
        border: Border.all(
          color: isPerfect ? const Color(0xFF66BB6A) : Colors.white.withValues(alpha: floating ? 0.22 : 0.16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPerfect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: accent,
            size: 20,
          ),
          if (directionIcon != null) ...[
            const SizedBox(width: DesignTokens.spacing8),
            Icon(directionIcon, color: accent, size: 20),
          ],
          const SizedBox(width: DesignTokens.spacing8),
          Flexible(
            child: Text(
              message,
              maxLines: floating ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: floating ? 13 : 14,
                fontWeight: FontWeight.w600,
                color: accent,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
