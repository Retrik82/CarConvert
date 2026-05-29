import 'package:flutter/material.dart';

class FrameGuidePainter extends CustomPainter {
  final bool isPerfect;

  FrameGuidePainter({this.isPerfect = false});

  @override
  void paint(Canvas canvas, Size size) {
    final borderColor = isPerfect ? Colors.greenAccent : Colors.white70;
    final paint = Paint()
      ..color = borderColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final rect = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.22,
      size.width * 0.84,
      size.height * 0.48,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.drawRRect(rrect, paint);

    final cornerLen = 28.0;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    void corner(Offset start, Offset end1, Offset end2) {
      canvas.drawLine(start, end1, cornerPaint);
      canvas.drawLine(start, end2, cornerPaint);
    }

    corner(rect.topLeft, rect.topLeft + Offset(cornerLen, 0), rect.topLeft + Offset(0, cornerLen));
    corner(rect.topRight, rect.topRight + Offset(-cornerLen, 0), rect.topRight + Offset(0, cornerLen));
    corner(rect.bottomLeft, rect.bottomLeft + Offset(cornerLen, 0), rect.bottomLeft + Offset(0, -cornerLen));
    corner(rect.bottomRight, rect.bottomRight + Offset(-cornerLen, 0), rect.bottomRight + Offset(0, -cornerLen));
  }

  @override
  bool shouldRepaint(covariant FrameGuidePainter oldDelegate) =>
      oldDelegate.isPerfect != isPerfect;
}
