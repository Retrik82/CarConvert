import 'package:flutter/material.dart';

import '../utils/frame_crop.dart';

class FrameGuidePainter extends CustomPainter {
  final bool isPerfect;

  FrameGuidePainter({this.isPerfect = false});

  static Rect guideRect(Size size) {
    return Rect.fromLTWH(
      size.width * frameCropLeft,
      size.height * frameCropTop,
      size.width * frameCropWidth,
      size.height * frameCropHeight,
    );
  }

  static RRect guideRRect(Size size) {
    return RRect.fromRectAndRadius(guideRect(size), const Radius.circular(16));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = guideRect(size);
    final rrect = guideRRect(size);
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
  bool shouldRepaint(covariant FrameGuidePainter oldDelegate) => oldDelegate.isPerfect != isPerfect;
}
