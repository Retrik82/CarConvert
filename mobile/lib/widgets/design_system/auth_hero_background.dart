import 'package:flutter/material.dart';

import '../../core/assets/bundled_assets.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';
import '../app_logo.dart';

/// Full-width hero used on auth screens — studio photo with logo overlay.
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
          Image.asset(
            BundledAssets.authHero,
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.55),
                  Colors.white.withValues(alpha: 0.92),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppLogo(
                  iconSize: 36,
                  titleSize: 20,
                  showTagline: false,
                  centered: false,
                  useImageLogo: true,
                ),
                const Spacer(),
                Text(
                  context.strings.appTagline,
                  style: tokens.textStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
