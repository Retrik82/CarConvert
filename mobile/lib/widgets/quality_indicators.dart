import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QualityIndicators extends StatelessWidget {
  final double framingScore;
  final double lightingScore;
  final double focusScore;

  const QualityIndicators({
    super.key,
    required this.framingScore,
    required this.lightingScore,
    required this.focusScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _scoreRow('Framing', framingScore),
          const SizedBox(height: 10),
          _scoreRow('Lighting', lightingScore),
          const SizedBox(height: 10),
          _scoreRow('Focus', focusScore),
        ],
      ),
    );
  }

  Widget _scoreRow(String label, double score) {
    final color = score >= 0.75
        ? AppTheme.success
        : score >= 0.5
            ? Colors.white.withValues(alpha: 0.85)
            : const Color(0xFFE57373);

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTheme.textStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70),
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
          style: AppTheme.textStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
        ),
      ],
    );
  }
}
