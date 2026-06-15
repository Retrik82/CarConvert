import 'package:flutter/material.dart';

import '../models/hint_response.dart';
import '../overlays/frame_guide_painter.dart';
import '../utils/frame_crop.dart';

/// Frame guide drawn on top of the camera preview area only.
class CaptureHintOverlay extends StatelessWidget {
  final HintResponse? hint;
  final FrameCropSpec crop;

  const CaptureHintOverlay({
    super.key,
    required this.hint,
    required this.crop,
  });

  @override
  Widget build(BuildContext context) {
    final isPerfect = hint?.isPerfect ?? false;

    return IgnorePointer(
      child: CustomPaint(
        painter: FrameGuidePainter(isPerfect: isPerfect, crop: crop),
        size: Size.infinite,
      ),
    );
  }
}
