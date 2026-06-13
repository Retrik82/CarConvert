import 'package:flutter/material.dart';

import '../models/background.dart';
import 'authenticated_background_image.dart';

/// Catalog preview — server-baked BMW M4 on angle-matched background.
class BackgroundScenePreview extends StatelessWidget {
  final BackgroundPreset preset;
  final String? angle;
  final BorderRadius? borderRadius;
  /// When false, shows the empty studio background (no car) — e.g. capture toolbar chip.
  final bool composed;

  const BackgroundScenePreview({
    super.key,
    required this.preset,
    this.angle,
    this.borderRadius,
    this.composed = true,
  });

  String? _previewPath() {
    final variant = angle != null ? preset.variantByAngle(angle!) : preset.defaultVariant;
    var path = variant?.previewUrl ?? preset.previewUrl;
    if (!composed && path != null) {
      path = path.replaceFirst('/preview/', '/image/');
    }
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final previewPath = _previewPath();

    Widget child = AuthenticatedBackgroundImage(
      previewPath: previewPath,
      fit: BoxFit.cover,
    );

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
