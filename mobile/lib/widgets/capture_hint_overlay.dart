import 'package:flutter/material.dart';

import '../models/hint_response.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_arrow.dart';
import '../widgets/quality_indicators.dart';
import '../overlays/frame_guide_painter.dart';

class CaptureHintOverlay extends StatelessWidget {
  final HintResponse? hint;
  final String status;

  const CaptureHintOverlay({
    super.key,
    required this.hint,
    required this.status,
  });

  String _guidanceMessage() {
    if (hint == null) {
      if (status.isNotEmpty && status != 'Initializing...') return status;
      return 'Point the camera at the car';
    }
    final type = hint!.hint;
    switch (type) {
      case 'move_left':
        return 'Move camera left';
      case 'move_right':
        return 'Move camera right';
      case 'move_back':
        return 'Step back';
      case 'move_closer':
        return 'Move closer';
      case 'align_car':
        return 'Car not fully in frame';
      case 'no_car_detected':
        return 'Car not fully in frame';
      case 'perfect_frame':
        return 'Perfect framing — take the photo';
      default:
        if (hint!.confidence < 0.45) return 'Improve focus';
        return hint!.message;
    }
  }

  double get _framingScore {
    final s = hint?.scores;
    if (s == null) return 0.4;
    return ((s.centering + s.angle) / 2).clamp(0, 1);
  }

  double get _lightingScore {
    if (hint == null) return 0.5;
    if (hint!.confidence < 0.35) return 0.35;
    return (0.55 + hint!.confidence * 0.35).clamp(0, 1);
  }

  double get _focusScore {
    final s = hint?.scores;
    if (s == null) return 0.45;
    return ((s.distance + s.angle) / 2).clamp(0, 1);
  }

  Color _overlayColor() {
    final colorName = hint?.overlay.color ?? 'yellow';
    switch (colorName) {
      case 'green':
        return AppTheme.success;
      case 'red':
        return const Color(0xFFE57373);
      default:
        return Colors.white.withValues(alpha: 0.9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPerfect = hint?.isPerfect ?? false;
    final lowLight = _lightingScore < 0.5;
    final message = lowLight && !isPerfect ? 'Low lighting' : _guidanceMessage();

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: FrameGuidePainter(isPerfect: isPerfect)),
          if (hint != null && hint!.overlay.arrow != 'none')
            Center(child: AnimatedArrow(direction: hint!.overlay.arrow, color: _overlayColor())),
          Positioned(
            top: MediaQuery.of(context).padding.top + 120,
            left: 16,
            right: 16,
            child: _HintCard(
              message: message,
              confidence: hint?.confidence ?? 0,
              isPerfect: isPerfect,
            ),
          ),
          Positioned(
            bottom: 160,
            left: 16,
            right: 16,
            child: QualityIndicators(
              framingScore: _framingScore,
              lightingScore: _lightingScore,
              focusScore: _focusScore,
            ),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String message;
  final double confidence;
  final bool isPerfect;

  const _HintCard({
    required this.message,
    required this.confidence,
    required this.isPerfect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingElement),
      decoration: BoxDecoration(
        color: isPerfect
            ? AppTheme.success.withValues(alpha: 0.88)
            : Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        border: Border.all(
          color: isPerfect ? AppTheme.success : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: AppTheme.textStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppTheme.white),
          ),
          if (!isPerfect) ...[
            const SizedBox(height: 6),
            Text(
              'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
              style: AppTheme.textStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}
