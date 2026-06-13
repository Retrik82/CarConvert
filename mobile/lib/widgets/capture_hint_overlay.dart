import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/l10n/hint_localizer.dart';
import '../core/theme/design_tokens.dart';
import '../models/hint_response.dart';
import '../overlays/frame_guide_painter.dart';
import '../widgets/animated_arrow.dart';
import '../widgets/quality_indicators.dart';

class CaptureHintOverlay extends StatelessWidget {
  final HintResponse? hint;
  final String status;

  const CaptureHintOverlay({
    super.key,
    required this.hint,
    required this.status,
  });

  double _framingScore(HintResponse? hint) {
    final s = hint?.scores;
    if (s == null) return 0.4;
    return ((s.centering + s.angle) / 2).clamp(0, 1);
  }

  double _lightingScore(HintResponse? hint) {
    if (hint == null) return 0.5;
    if (hint.confidence < 0.35) return 0.35;
    return (0.55 + hint.confidence * 0.35).clamp(0, 1);
  }

  double _focusScore(HintResponse? hint) {
    final s = hint?.scores;
    if (s == null) return 0.45;
    return ((s.distance + s.angle) / 2).clamp(0, 1);
  }

  Color _overlayColor(HintResponse? hint) {
    final colorName = hint?.overlay.color ?? 'yellow';
    return switch (colorName) {
      'green' => const Color(0xFF66BB6A),
      'red' => const Color(0xFFE57373),
      _ => Colors.white.withValues(alpha: 0.92),
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final localizer = HintLocalizer(s);
    final isPerfect = hint?.isPerfect ?? false;
    final lighting = _lightingScore(hint);
    final lowLight = lighting < 0.5;
    final message = lowLight && !isPerfect ? s.advisorLowLight : localizer.message(hint: hint, status: localizer.statusOrConnecting(status));

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: FrameGuidePainter(isPerfect: isPerfect)),
          if (hint != null && hint!.overlay.arrow != 'none')
            Center(child: AnimatedArrow(direction: hint!.overlay.arrow, color: _overlayColor(hint))),
          Positioned(
            top: MediaQuery.of(context).padding.top + 108,
            left: DesignTokens.screenPaddingH,
            right: DesignTokens.screenPaddingH,
            child: _AdvisorCard(
              message: message,
              confidence: hint?.confidence ?? 0,
              isPerfect: isPerfect,
            ),
          ),
          Positioned(
            bottom: 168,
            left: DesignTokens.screenPaddingH,
            right: DesignTokens.screenPaddingH,
            child: QualityIndicators(
              framingScore: _framingScore(hint),
              lightingScore: lighting,
              focusScore: _focusScore(hint),
              labels: QualityLabels(
                framing: s.qualityFraming,
                lighting: s.qualityLighting,
                focus: s.qualityFocus,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvisorCard extends StatelessWidget {
  final String message;
  final double confidence;
  final bool isPerfect;

  const _AdvisorCard({
    required this.message,
    required this.confidence,
    required this.isPerfect,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.strings;

    return AnimatedContainer(
      duration: DesignTokens.durationNormal,
      curve: DesignTokens.curveStandard,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacing16, vertical: DesignTokens.spacing12),
      decoration: BoxDecoration(
        color: isPerfect ? const Color(0xE62E7D32) : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
        border: Border.all(
          color: isPerfect ? const Color(0xFF66BB6A) : Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isPerfect ? Icons.check_circle_rounded : Icons.center_focus_strong_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: DesignTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                if (!isPerfect) ...[
                  const SizedBox(height: 4),
                  Text(
                    s.confidenceLabel((confidence * 100).round()),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
