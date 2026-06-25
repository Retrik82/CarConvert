import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../utils/frame_crop.dart';

/// Photo preview sized to its natural aspect ratio so it is never stretched.
class FramedPhotoPreview extends StatelessWidget {
  final Uint8List imageBytes;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Decoration? decoration;
  final List<Widget> overlays;

  const FramedPhotoPreview({
    super.key,
    required this.imageBytes,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.decoration,
    this.overlays = const [],
  });

  @override
  Widget build(BuildContext context) {
    final aspectRatio = imageAspectRatio(imageBytes) ?? (4 / 3);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: DecoratedBox(
                decoration: decoration ?? const BoxDecoration(),
                child: ClipRRect(
                  borderRadius: borderRadius ?? BorderRadius.zero,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(
                        imageBytes,
                        fit: fit,
                        alignment: Alignment.center,
                        gaplessPlayback: true,
                      ),
                      ...overlays,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
