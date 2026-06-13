import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../models/background.dart';
import 'authenticated_background_image.dart';
import 'design_system/car_assets.dart';
import 'design_system/car_overlay.dart';

/// Background preview: server-rendered studio image with car overlay.
class BackgroundScenePreview extends StatelessWidget {
  final BackgroundPreset preset;
  final String? angle;
  final bool showCar;
  final BorderRadius? borderRadius;

  const BackgroundScenePreview({
    super.key,
    required this.preset,
    this.angle,
    this.showCar = true,
    this.borderRadius,
  });

  String? _previewPath() {
    final variant = angle != null ? preset.variantByAngle(angle!) : preset.defaultVariant;
    return variant?.previewUrl ?? preset.previewUrl;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final previewPath = _previewPath();
    final carView = CarAssets.fromBackgroundAngle(angle);
    final displayCar = showCar && CarOverlay.supportsBackgroundAngle(angle);

    Widget child = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        AuthenticatedBackgroundImage(
          previewPath: previewPath,
          fit: BoxFit.contain,
        ),
        if (displayCar)
          CarOverlay(
            view: carView,
            tokens: tokens,
            style: CarOverlayStyle.backgroundPreview,
          ),
      ],
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
