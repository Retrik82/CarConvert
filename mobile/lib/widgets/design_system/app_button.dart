import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expanded = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = widget.onPressed != null && !widget.loading;
    final isPrimary = widget.variant == AppButtonVariant.primary;

    final (bg, fg, border) = switch (widget.variant) {
      AppButtonVariant.primary => (null, tokens.onAccent, Colors.transparent),
      AppButtonVariant.secondary => (tokens.surfaceMuted, tokens.textPrimary, tokens.border),
      AppButtonVariant.ghost => (Colors.transparent, tokens.textSecondary, Colors.transparent),
    };

    final child = AnimatedContainer(
      duration: DesignTokens.durationFast,
      curve: DesignTokens.curveStandard,
      height: DesignTokens.minTapTarget + 8,
      width: widget.expanded ? double.infinity : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.expanded ? DesignTokens.spacing24 : DesignTokens.spacing16,
      ),
      transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
      decoration: BoxDecoration(
        color: isPrimary ? null : (enabled ? bg : bg?.withValues(alpha: 0.4)),
        gradient: isPrimary && enabled ? tokens.primaryGradient : null,
        borderRadius: BorderRadius.circular(DesignTokens.radiusButton),
        border: Border.all(color: border.withValues(alpha: enabled ? 1 : 0.4)),
        boxShadow: isPrimary && enabled
            ? [
                BoxShadow(
                  color: tokens.accent.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (widget.loading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          else ...[
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 20, color: enabled ? fg : fg.withValues(alpha: 0.5)),
              const SizedBox(width: DesignTokens.spacing8),
            ],
            Flexible(
              child: Text(
                widget.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: tokens.textStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: enabled ? fg : fg.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: Semantics(button: true, enabled: enabled, label: widget.label, child: child),
    );
  }
}
