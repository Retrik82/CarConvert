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
  final CarOverlayStyle style;

  const CarOverlay({
    super.key,
    required this.view,
    required this.tokens,
    this.bodyColor,
    this.style = CarOverlayStyle.hero,
  });

  static bool supportsBackgroundAngle(String? angle) => angle != 'interior';

  @override
  Widget build(BuildContext context) {
    final imagePath = bodyColor != null
        ? CarAssets.neutralPath(view)
        : CarAssets.path(view, isDark: tokens.isDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final padding = switch (style) {
          CarOverlayStyle.hero => EdgeInsets.fromLTRB(w * 0.06, h * 0.06, w * 0.06, h * 0.08),
          CarOverlayStyle.backgroundPreview => EdgeInsets.fromLTRB(w * 0.05, h * 0.06, w * 0.05, h * 0.24),
        };

        return Padding(
          padding: padding,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClipRect(
              child: RemoteCarImage(
                imagePath: imagePath,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                tintColor: bodyColor,
              ),
            ),
          ),
        );
      },
    );
  }
}
