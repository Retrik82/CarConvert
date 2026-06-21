import 'package:flutter/material.dart';

import '../../core/assets/bundled_assets.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';

/// Single static hero image for onboarding — car + studio baked into one asset.
class OnboardingHeroImage extends StatelessWidget {
  final double? height;

  const OnboardingHeroImage({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
          boxShadow: tokens.elevatedShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          BundledAssets.onboardingWelcomeHero,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
