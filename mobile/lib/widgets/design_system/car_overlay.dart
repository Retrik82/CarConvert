import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'car_assets.dart';
import '../remote_car_image.dart';

enum CarOverlayStyle {
  /// Splash / login / welcome / configurator — car only on transparent canvas.
  hero,
  /// Composited on server background — wheels align to rendered podium.
  backgroundPreview,
}

/// Transparent car render loaded from the server, sized to fit without clipping.
class CarOverlay extends StatelessWidget {
  final CarViewAngle view;
  final AppTokens tokens;
  final Color? bodyColor;
  final CarPaintVariant? variant;
  final CarOverlayStyle style;

  const CarOverlay({
    super.key,
    required this.view,
    required this.tokens,
    this.bodyColor,
    this.variant,
    this.style = CarOverlayStyle.hero,
  });

  static bool supportsBackgroundAngle(String? angle) => angle != 'interior';

  @override
  Widget build(BuildContext context) {
    final imagePath = bodyColor != null
        ? CarAssets.neutralPath(view)
        : CarAssets.path(view, isDark: tokens.isDark, variant: variant);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        if (style == CarOverlayStyle.hero) {
          return Padding(
            padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.06, w * 0.06, h * 0.08),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RemoteCarImage(
                imagePath: imagePath,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                tintColor: bodyColor,
              ),
            ),
          );
        }

        // Background picker — use the PNG at its natural aspect ratio, scaled only to fit the frame.
        final groundY = h * 0.70;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: groundY,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: RemoteCarImage(
                  imagePath: imagePath,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  tintColor: bodyColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
