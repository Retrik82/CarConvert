import 'package:flutter/material.dart';

import '../core/assets/bundled_assets.dart';
import '../models/background.dart';
import 'authenticated_background_image.dart';

/// Bundled or remote studio scene preview (16:9 preset photographs).
class BackgroundScenePreview extends StatelessWidget {
  final BackgroundPreset preset;
  final String? angle;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const BackgroundScenePreview({
    super.key,
    required this.preset,
    this.angle,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  BackgroundVariant? _variant() {
    return angle != null ? preset.variantByAngle(angle!) : preset.defaultVariant;
  }

  String? _scenePath() {
    final variant = _variant();
    return variant?.previewUrl ?? preset.previewUrl;
  }

  String? _bundledAssetPath() {
    if (preset.isCustom) return null;

    final variant = _variant();
    final resolvedAngle = variant?.angle ?? angle;
    if (resolvedAngle == null || !BundledAssets.presetAngles.contains(resolvedAngle)) {
      return null;
    }

    final resolvedSlug = _resolveBundledSlug();
    if (resolvedSlug == null) return null;

    return BundledAssets.presetBackgroundAssetPath(resolvedSlug, resolvedAngle);
  }

  String? _resolveBundledSlug() {
    if (BundledAssets.presetSlugs.contains(preset.slug)) {
      return preset.slug;
    }

    if (preset.id.startsWith('local-')) {
      final localSlug = preset.id.substring('local-'.length);
      if (BundledAssets.presetSlugs.contains(localSlug)) {
        return localSlug;
      }
    }

    final normalized = preset.name.trim().toLowerCase();
    if (normalized == 'gray showroom') return 'gray-showroom';
    if (normalized == 'auto workshop') return 'auto-workshop';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _bundledAssetPath();

    Widget child;
    if (assetPath != null) {
      child = Image.asset(
        assetPath,
        fit: fit,
        alignment: Alignment.center,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => AuthenticatedBackgroundImage(
          previewPath: _scenePath(),
          presetSlug: null,
          angle: null,
          fit: fit,
        ),
      );
    } else {
      child = AuthenticatedBackgroundImage(
        previewPath: _scenePath(),
        presetSlug: null,
        angle: null,
        fit: fit,
      );
    }

    child = SizedBox.expand(child: child);

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
