import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';

class CaptureHintBar extends StatelessWidget {
  final String message;
  final bool isPerfect;
  final String arrowDirection;

  const CaptureHintBar({
    super.key,
    required this.message,
    this.isPerfect = false,
    this.arrowDirection = 'none',
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
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing16,
        vertical: DesignTokens.spacing12,
      ),
      decoration: BoxDecoration(
        color: isPerfect ? const Color(0xE62E7D32) : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
        border: Border.all(
          color: isPerfect ? const Color(0xFF66BB6A) : Colors.white.withValues(alpha: 0.16),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
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
