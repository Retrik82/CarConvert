import 'package:flutter/material.dart';

import '../models/hint_response.dart';
import 'animated_arrow.dart';
import '../overlays/frame_guide_painter.dart';

class CameraHintOverlay extends StatelessWidget {
  final HintResponse? hint;
  final String status;

  const CameraHintOverlay({
    super.key,
    required this.hint,
    required this.status,
  });

  Color _overlayColor() {
    final colorName = hint?.overlay.color ?? 'yellow';
    switch (colorName) {
      case 'green':
        return Colors.greenAccent;
      case 'red':
        return Colors.redAccent;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPerfect = hint?.isPerfect ?? false;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: FrameGuidePainter(isPerfect: isPerfect)),
          if (hint != null && hint!.overlay.arrow != 'none')
            Center(child: AnimatedArrow(direction: hint!.overlay.arrow, color: _overlayColor())),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: _StatusPill(text: status),
          ),
          Positioned(
            bottom: 140,
            left: 20,
            right: 20,
            child: _HintCard(
              message: hint?.message ?? 'Наведи камеру на машину',
              confidence: hint?.confidence ?? 0,
              isPerfect: isPerfect,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  const _StatusPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPerfect ? Colors.green.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPerfect ? Colors.greenAccent : Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Уверенность: ${(confidence * 100).toStringAsFixed(0)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
