import 'package:flutter/material.dart';

import '../../core/assets/bundled_assets.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';
import 'car_assets.dart';
import 'car_overlay.dart';

/// Auth/register hero — same BMW overlay on empty studio background.
class AuthHeroBackground extends StatelessWidget {
  final double height;

  const AuthHeroBackground({super.key, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
        boxShadow: tokens.elevatedShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(BundledAssets.showroomWhiteEmpty, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.5),
                  Colors.white.withValues(alpha: 0.88),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          CarOverlay(
            view: CarViewAngle.threeQuarterRight,
            tokens: tokens,
            style: CarOverlayStyle.backgroundPreview,
            variant: CarPaintVariant.black,
          ),
        ],
      ),
    );
  }
}
