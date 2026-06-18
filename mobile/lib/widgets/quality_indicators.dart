import 'package:flutter/material.dart';

import '../core/theme/capture_chrome.dart';
import '../core/theme/design_tokens.dart';

class QualityLabels {
  final String framing;
  final String lighting;
  final String focus;

  const QualityLabels({
    required this.framing,
    required this.lighting,
    required this.focus,
  });
}

class QualityIndicators extends StatelessWidget {
  final double framingScore;
  final double lightingScore;
  final double focusScore;
  final QualityLabels labels;

  const QualityIndicators({
    super.key,
    required this.framingScore,
    required this.lightingScore,
    required this.focusScore,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacing16),
      decoration: BoxDecoration(
        color: CaptureChrome.surfaceGlass,
        borderRadius: BorderRadius.circular(DesignTokens.radiusInput),
        border: Border.all(color: CaptureChrome.borderAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _scoreRow(labels.framing, framingScore),
          const SizedBox(height: DesignTokens.spacing12),
          _scoreRow(labels.lighting, lightingScore),
          const SizedBox(height: DesignTokens.spacing12),
          _scoreRow(labels.focus, focusScore),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, double score) {
    final color = score >= 0.75
        ? CaptureChrome.perfect
        : score >= 0.5
            ? CaptureChrome.accent
            : CaptureChrome.warning;

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: CaptureChrome.textMuted,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.clamp(0, 1),
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              color: color,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spacing8),
        Text(
          '${(score * 100).round()}%',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
