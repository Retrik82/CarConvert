import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import '../models/background.dart';
import 'background_scene_preview.dart';

/// Seven-angle preview strip — same camera positions for every background card.
class BackgroundAnglesGallery extends StatelessWidget {
  final BackgroundPreset preset;
  final double itemHeight;
  final bool enableZoom;

  const BackgroundAnglesGallery({
    super.key,
    required this.preset,
    this.itemHeight = 72,
    this.enableZoom = false,
  });

  static const angles = [
    'three_quarter_left',
    'three_quarter_right',
    'left',
    'right',
    'front',
    'rear',
    'interior',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: angles.length,
        separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.spacing8),
        itemBuilder: (context, index) {
          final angle = angles[index];
          final preview = ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: BackgroundScenePreview(preset: preset, angle: angle),
            ),
          );

          if (!enableZoom) return preview;

          return GestureDetector(
            onTap: () => openFullscreenBackgroundAngle(context, preset: preset, angle: angle),
            child: preview,
          );
        },
      ),
    );
  }
}

Future<void> openFullscreenBackgroundAngle(
  BuildContext context, {
  required BackgroundPreset preset,
  required String angle,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text('${preset.name} · $angle', style: const TextStyle(color: Colors.white, fontSize: 14)),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
        body: Container(
          color: ctx.tokens.textPrimary,
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: BackgroundScenePreview(preset: preset, angle: angle),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
