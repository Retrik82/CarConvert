import 'package:flutter/material.dart';

import '../core/theme/design_tokens.dart';
import '../models/background.dart';
import 'background_scene_preview.dart';

/// Seven-angle preview strip — same camera positions for every background card.
class BackgroundAnglesGallery extends StatelessWidget {
  final BackgroundPreset preset;
  final double itemHeight;

  const BackgroundAnglesGallery({
    super.key,
    required this.preset,
    this.itemHeight = 72,
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
          return ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: BackgroundScenePreview(preset: preset, angle: angle),
            ),
          );
        },
      ),
    );
  }
}
