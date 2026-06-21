import 'package:flutter/material.dart';

import '../../core/assets/bundled_assets.dart';
import '../../core/theme/design_tokens.dart';

/// Full-screen auth hero — white BMW M4 G82 in a premium showroom photo.
class AuthWelcomeBackground extends StatelessWidget {
  const AuthWelcomeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          BundledAssets.authWelcomeHero,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.92),
                Colors.white.withValues(alpha: 0.35),
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0.96),
              ],
              stops: const [0.0, 0.18, 0.45, 0.72, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                DesignTokens.textDark.withValues(alpha: 0.03),
                Colors.transparent,
                DesignTokens.textDark.withValues(alpha: 0.06),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
