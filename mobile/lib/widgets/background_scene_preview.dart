import 'package:flutter/material.dart';

import '../core/assets/bundled_assets.dart';
import '../models/background.dart';
import 'authenticated_background_image.dart';

/// Composed studio scene — bundled presets load instantly from app assets.
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

  BackgroundVariant? _variant() {
    return angle != null ? preset.variantByAngle(angle!) : preset.defaultVariant;
  }

  String? _scenePath() {
    final variant = _variant();
    return variant?.previewUrl ?? preset.previewUrl;
  }

  String? _bundledAngle() {
    if (preset.isCustom) return null;
    if (!BundledAssets.presetSlugs.contains(preset.slug)) return null;
    final variant = _variant();
    final resolved = variant?.angle ?? angle;
    if (resolved == null || !BundledAssets.presetAngles.contains(resolved)) {
      return null;
    }
    return resolved;
  }

  @override
  Widget build(BuildContext context) {
    final bundledAngle = _bundledAngle();
    final useBundledAssets = bundledAngle != null;

    Widget child = AuthenticatedBackgroundImage(
      previewPath: useBundledAssets ? null : _scenePath(),
      presetSlug: useBundledAssets ? preset.slug : null,
      angle: bundledAngle,
      fit: BoxFit.contain,
    );

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
