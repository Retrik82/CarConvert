import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';
import 'car_assets.dart';
import 'car_overlay.dart';

/// BMW M4 G82 hero — theme-aware car image only (no podium strip).
class CarHero extends StatelessWidget {
  final Color? bodyColor;
  final double height;
  final bool animate;
  final CarViewAngle view;

  const CarHero({
    super.key,
    this.bodyColor,
    this.height = 280,
    this.animate = true,
    this.view = CarViewAngle.sideRight,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0.96 : 1, end: 1),
      duration: DesignTokens.durationSlow,
      curve: DesignTokens.curveEmphasized,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CarOverlay(
          view: view,
          tokens: tokens,
          bodyColor: bodyColor,
          style: CarOverlayStyle.hero,
        ),
      ),
    );
  }
}
