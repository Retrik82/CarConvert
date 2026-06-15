import 'package:flutter/material.dart';

import '../utils/frame_crop.dart';

class FrameGuidePainter extends CustomPainter {
  final bool isPerfect;
  final FrameCropSpec crop;

  FrameGuidePainter({
    this.isPerfect = false,
    FrameCropSpec? crop,
  }) : crop = crop ?? portraitFrameCrop;

  static Rect guideRect(Size size, {FrameCropSpec? crop}) {
    final spec = crop ?? portraitFrameCrop;
    return Rect.fromLTWH(
      size.width * spec.left,
      size.height * spec.top,
      size.width * spec.width,
      size.height * spec.height,
    );
  }

  static RRect guideRRect(Size size, {FrameCropSpec? crop}) {
    return RRect.fromRectAndRadius(guideRect(size, crop: crop), const Radius.circular(16));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = guideRect(size, crop: crop);
    final rrect = guideRRect(size, crop: crop);
    final borderColor = isPerfect ? const Color(0xFF66BB6A) : Colors.white;

    final dimPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(
      dimPath,
      Paint()..color = Colors.black.withValues(alpha: isPerfect ? 0.35 : 0.5),
    );

    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(rrect, borderPaint);

    const cornerLen = 24.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    void corner(Offset start, Offset end1, Offset end2) {
      canvas.drawLine(start, end1, cornerPaint);
      canvas.drawLine(start, end2, cornerPaint);
    }

    corner(rect.topLeft, rect.topLeft + const Offset(cornerLen, 0), rect.topLeft + const Offset(0, cornerLen));
    corner(rect.topRight, rect.topRight + const Offset(-cornerLen, 0), rect.topRight + const Offset(0, cornerLen));
    corner(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(cornerLen, 0),
      rect.bottomLeft + const Offset(0, -cornerLen),
    );
    corner(
      rect.bottomRight,
      rect.bottomRight + const Offset(-cornerLen, 0),
      rect.bottomRight + const Offset(0, -cornerLen),
    );
  }

  @override
  bool shouldRepaint(covariant FrameGuidePainter oldDelegate) {
    return oldDelegate.isPerfect != isPerfect || oldDelegate.crop != crop;
  }
}
