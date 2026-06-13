import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _scoreRow(labels.framing, framingScore),
          const SizedBox(height: 10),
          _scoreRow(labels.lighting, lightingScore),
          const SizedBox(height: 10),
          _scoreRow(labels.focus, focusScore),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, double score) {
    final color = score >= 0.75
        ? const Color(0xFF66BB6A)
        : score >= 0.5
            ? Colors.white.withValues(alpha: 0.85)
            : const Color(0xFFE57373);

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white.withValues(alpha: 0.7)),
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
        const SizedBox(width: 8),
        Text(
          '${(score * 100).round()}%',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
