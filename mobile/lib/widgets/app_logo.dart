import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';

class AppLogo extends StatelessWidget {
  final double iconSize;
  final double titleSize;
  final bool showTagline;
  final bool centered;

  const AppLogo({
    super.key,
    this.iconSize = 48,
    this.titleSize = 28,
    this.showTagline = true,
    this.centered = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final name = s.appName;
    final splitIndex = name.length > 4 ? (name.length * 0.45).round() : name.length ~/ 2;
    final firstPart = name.substring(0, splitIndex);
    final secondPart = name.substring(splitIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: tokens.primaryGradient,
            borderRadius: BorderRadius.circular(iconSize * 0.28),
            boxShadow: [
              BoxShadow(
                color: tokens.accent.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: iconSize * 0.5,
            color: tokens.onAccent,
          ),
        ),
        SizedBox(height: DesignTokens.spacing12),
        Row(
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Text(
              firstPart,
              style: tokens.textStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => tokens.primaryGradient.createShader(bounds),
              child: Text(
                secondPart,
                style: tokens.textStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: DesignTokens.spacing8),
          Text(
            s.appTagline.toUpperCase(),
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: tokens.textStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: tokens.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

/// Highlights a substring with the brand gradient.
class GradientHighlightText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle baseStyle;

  const GradientHighlightText({
    super.key,
    required this.text,
    required this.highlight,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final index = text.indexOf(highlight);
    if (index < 0) {
      return Text(text, style: baseStyle);
    }

    final before = text.substring(0, index);
    final after = text.substring(index + highlight.length);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: ShaderMask(
              shaderCallback: (bounds) => tokens.primaryGradient.createShader(bounds),
              child: Text(
                highlight,
                style: baseStyle.copyWith(color: Colors.white),
              ),
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
