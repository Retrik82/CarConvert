import 'package:flutter/material.dart';

import '../core/assets/bundled_assets.dart';
import '../core/theme/app_tokens.dart';
import '../models/background.dart';
import 'authenticated_background_image.dart';
import 'design_system/car_assets.dart';
import 'design_system/car_overlay.dart';

/// Bundled or remote studio scene preview with optional BMW overlay at native scale.
class BackgroundScenePreview extends StatelessWidget {
  final BackgroundPreset preset;
  final String? angle;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final bool showCar;

  const BackgroundScenePreview({
    super.key,
    required this.preset,
    this.angle,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.showCar = true,
  });

  BackgroundVariant? _variant() {
    return angle != null ? preset.variantByAngle(angle!) : preset.defaultVariant;
  }

  String? _scenePath() {
    final variant = _variant();
    return variant?.previewUrl ?? preset.previewUrl;
  }

  String? _resolvedAngle() {
    final variant = _variant();
    return variant?.angle ?? angle;
  }

  String? _bundledAssetPath() {
    if (preset.isCustom) return null;

    final resolvedAngle = _resolvedAngle();
    if (resolvedAngle == null || !BundledAssets.presetAngles.contains(resolvedAngle)) {
      return null;
    }

    final resolvedSlug = _resolveBundledSlug();
    if (resolvedSlug == null) return null;

    return BundledAssets.presetBackgroundAssetPath(resolvedSlug, resolvedAngle);
  }

  String? _emptyBackgroundAssetPath() {
    final resolvedSlug = _resolveBundledSlug();
    if (resolvedSlug == null) return null;
    return BundledAssets.sliderAfterBackgroundForPreset(resolvedSlug);
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

  Widget _buildBackground() {
    final assetPath = (showCar ? _emptyBackgroundAssetPath() : null) ?? _bundledAssetPath();

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: fit,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => AuthenticatedBackgroundImage(
          previewPath: _scenePath(),
          presetSlug: null,
          angle: null,
          fit: fit,
        ),
      );
    }

    return AuthenticatedBackgroundImage(
      previewPath: _scenePath(),
      presetSlug: null,
      angle: null,
      fit: fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAngle = _resolvedAngle();
    final displayCar = showCar && CarOverlay.supportsBackgroundAngle(resolvedAngle);

    Widget child;
    if (displayCar) {
      final tokens = context.tokens;
      child = Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _buildBackground()),
          CarOverlay(
            view: CarAssets.fromBackgroundAngle(resolvedAngle),
            tokens: tokens,
            style: CarOverlayStyle.backgroundPreview,
          ),
        ],
      );
    } else {
      child = _buildBackground();
    }

    child = SizedBox.expand(child: child);

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
