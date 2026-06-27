import 'package:flutter/material.dart';

import '../core/assets/bundled_assets.dart';
import '../models/background.dart';
import 'authenticated_background_image.dart';

/// Bundled or remote studio scene preview (16:9 preset photographs).
class BackgroundScenePreview extends StatelessWidget {
  static const previewAspectRatio = 16 / 9;

  final BackgroundPreset preset;
  final String? angle;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const BackgroundScenePreview({
    super.key,
    required this.preset,
    this.angle,
    this.borderRadius,
    this.fit = BoxFit.contain,
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

  Widget _buildImage() {
    final assetPath = _bundledAssetPath();

    if (assetPath != null) {
      return Image.asset(
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
    Widget child = LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        if (!maxW.isFinite || !maxH.isFinite || maxW <= 0 || maxH <= 0) {
          return _buildImage();
        }

        // Keep 16:9 photographs at native proportions — never stretch or narrow.
        final widthLimited = maxW <= maxH * previewAspectRatio;
        final width = widthLimited ? maxW : maxH * previewAspectRatio;
        final height = widthLimited ? maxW / previewAspectRatio : maxH;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: _buildImage(),
          ),
        );
      },
    );

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}
