import 'package:flutter/material.dart';

import '../models/hint_response.dart';
import '../overlays/frame_guide_painter.dart';

/// Frame guide drawn on top of the camera preview area only.
class CaptureHintOverlay extends StatelessWidget {
  final HintResponse? hint;

  const CaptureHintOverlay({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    final isPerfect = hint?.isPerfect ?? false;

    return IgnorePointer(
      child: CustomPaint(
        painter: FrameGuidePainter(isPerfect: isPerfect),
        size: Size.infinite,
      ),
    );
  }
}
