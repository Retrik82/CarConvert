import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'car_assets.dart';
import '../remote_car_image.dart';

enum CarOverlayStyle {
  /// Splash / login / configurator — sized for local podium widget.
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
          CarOverlayStyle.hero => EdgeInsets.fromLTRB(w * 0.02, h * 0.04, w * 0.02, h * 0.20),
          CarOverlayStyle.backgroundPreview => EdgeInsets.fromLTRB(w * 0.04, h * 0.05, w * 0.04, h * 0.27),
        };

        return Padding(
          padding: padding,
          child: RemoteCarImage(
            imagePath: imagePath,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            tintColor: bodyColor,
          ),
        );
      },
    );
  }
}
