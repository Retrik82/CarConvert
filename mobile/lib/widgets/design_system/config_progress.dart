import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';

class ConfigProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const ConfigProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final progress = (currentStep + 1) / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: DesignTokens.durationNormal,
            curve: DesignTokens.curveEmphasized,
            builder: (_, value, __) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 3,
                backgroundColor: tokens.borderSubtle,
                color: tokens.accent,
              );
            },
          ),
        ),
        const SizedBox(height: DesignTokens.spacing12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(labels.length, (i) {
              final active = i == currentStep;
              final done = i < currentStep;
              return Padding(
                padding: EdgeInsets.only(right: i < labels.length - 1 ? DesignTokens.spacing16 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: DesignTokens.durationNormal,
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active || done ? tokens.accent : tokens.border,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacing8),
                    Text(
                      labels[i],
                      style: tokens.textStyle(
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? tokens.textPrimary : tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
