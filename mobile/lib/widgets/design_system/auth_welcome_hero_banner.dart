import 'package:flutter/material.dart';

import '../../core/assets/bundled_assets.dart';
import '../../core/theme/design_tokens.dart';

/// Reference-style hero banner — white BMW M4 G82, edge-to-edge between logo and copy.
class AuthWelcomeHeroBanner extends StatelessWidget {
  const AuthWelcomeHeroBanner({super.key});

  static const _white = DesignTokens.backgroundWhite;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.34;

    return SizedBox(
      width: double.infinity,
      height: height.clamp(220.0, 320.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            BundledAssets.authWelcomeHero,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _white,
                  Color(0xF5FFFFFF),
                  Color(0xCCFFFFFF),
                  Color(0x80FFFFFF),
                  Color(0x33FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0x00FFFFFF),
                  Color(0x26FFFFFF),
                  Color(0x66FFFFFF),
                  Color(0xA6FFFFFF),
                  Color(0xD9FFFFFF),
                  _white,
                ],
                stops: [
                  0.0,
                  0.05,
                  0.10,
                  0.16,
                  0.22,
                  0.30,
                  0.62,
                  0.72,
                  0.80,
                  0.88,
                  0.94,
                  1.0,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
