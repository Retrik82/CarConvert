import 'package:flutter/material.dart';

import '../models/background.dart';
import 'authenticated_background_image.dart';

/// Composed studio scene (room + BMW) served from the server.
class BackgroundScenePreview extends StatelessWidget {
  final BackgroundPreset preset;
  final String? angle;
  final BorderRadius? borderRadius;

  const BackgroundScenePreview({
    super.key,
    required this.preset,
    this.angle,
    this.borderRadius,
  });

  String? _scenePath() {
    final variant = angle != null ? preset.variantByAngle(angle!) : preset.defaultVariant;
    return variant?.previewUrl ?? preset.previewUrl;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = AuthenticatedBackgroundImage(
      previewPath: _scenePath(),
      fit: BoxFit.contain,
    );

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
