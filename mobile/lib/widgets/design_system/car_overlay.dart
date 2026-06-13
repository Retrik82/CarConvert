import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'car_assets.dart';
import '../remote_car_image.dart';

/// Transparent car render loaded from the server, sized to fit without clipping.
class CarOverlay extends StatelessWidget {
  final CarViewAngle view;
  final AppTokens tokens;
  final Color? bodyColor;
  final double heightFactor;
  final double bottomInsetFactor;

  const CarOverlay({
    super.key,
    required this.view,
    required this.tokens,
    this.bodyColor,
    this.heightFactor = 0.62,
    this.bottomInsetFactor = 0.08,
  });

  static bool supportsBackgroundAngle(String? angle) => angle != 'interior';

  @override
  Widget build(BuildContext context) {
    final imagePath = bodyColor != null
        ? CarAssets.neutralPath(view)
        : CarAssets.path(view, isDark: tokens.isDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final carHeight = h * heightFactor;
        final bottom = h * bottomInsetFactor;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, bottom),
            child: SizedBox(
              height: carHeight,
              width: constraints.maxWidth,
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
