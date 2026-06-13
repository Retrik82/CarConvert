import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';

/// Procedural premium car hero with podium, ambient glow, and theme-aware body.
class CarHero extends StatelessWidget {
  final Color? bodyColor;
  final double height;
  final bool animate;

  const CarHero({
    super.key,
    this.bodyColor,
    this.height = 280,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedBody = bodyColor ??
        (tokens.isDark ? tokens.carBodyDark : tokens.carBodyLight);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: animate ? 0.96 : 1, end: 1),
      duration: DesignTokens.durationSlow,
      curve: DesignTokens.curveEmphasized,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _CarHeroPainter(
            tokens: tokens,
            bodyColor: resolvedBody,
          ),
        ),
      ),
    );
  }
}

class _CarHeroPainter extends CustomPainter {
  final AppTokens tokens;
  final Color bodyColor;

  _CarHeroPainter({required this.tokens, required this.bodyColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawAmbient(canvas, size);
    _drawFloor(canvas, w, h);
    _drawPodium(canvas, w, h);
    _drawReflection(canvas, w, h);
    _drawCar(canvas, w, h);
    _drawGlow(canvas, w, h);
  }

  void _drawAmbient(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = RadialGradient(
      center: const Alignment(0, -0.3),
      radius: 1.2,
      colors: [
        tokens.heroAmbient,
        tokens.background.withValues(alpha: 0),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _drawFloor(Canvas canvas, double w, double h) {
    final floorY = h * 0.78;
    final rect = Rect.fromLTWH(0, floorY, w, h - floorY);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [tokens.heroFloor.withValues(alpha: 0.3), tokens.background],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _drawPodium(Canvas canvas, double w, double h) {
    final podiumW = w * 0.72;
    final podiumH = h * 0.06;
    final podiumX = (w - podiumW) / 2;
    final podiumY = h * 0.72;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(podiumX, podiumY, podiumW, podiumH),
      const Radius.circular(4),
    );

    final shadowPaint = Paint()
      ..color = tokens.shadow.withValues(alpha: tokens.isDark ? 0.5 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawRRect(rrect.shift(const Offset(0, 8)), shadowPaint);

    final podiumGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        tokens.heroPodium,
        tokens.heroPodium.withValues(alpha: 0.85),
      ],
    );
    canvas.drawRRect(
      rrect,
      Paint()..shader = podiumGradient.createShader(rrect.outerRect),
    );

    final edgePaint = Paint()
      ..color = tokens.border.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRRect(rrect, edgePaint);
  }

  void _drawReflection(Canvas canvas, double w, double h) {
    final reflectY = h * 0.76;
    final reflectW = w * 0.55;
    final reflectX = (w - reflectW) / 2;

    final rect = Rect.fromLTWH(reflectX, reflectY, reflectW, h * 0.08);
    final gradient = LinearGradient(
      colors: [
        tokens.carReflection.withValues(alpha: tokens.isDark ? 0.15 : 0.35),
        Colors.transparent,
      ],
    );
    canvas.drawOval(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );
  }

  void _drawCar(Canvas canvas, double w, double h) {
    final cx = w / 2;
    final cy = h * 0.52;
    final carW = w * 0.78;
    final carH = h * 0.28;

    final bodyPath = _buildCarBodyPath(cx, cy, carW, carH);

    final shadowPaint = Paint()
      ..color = tokens.shadow.withValues(alpha: tokens.isDark ? 0.6 : 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawPath(bodyPath.shift(const Offset(0, 12)), shadowPaint);

    final bodyGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(bodyColor, tokens.carHighlight, 0.35)!,
        bodyColor,
        Color.lerp(bodyColor, tokens.carBodyDark, 0.25)!,
      ],
      stops: const [0, 0.55, 1],
    );
    final bodyRect = Rect.fromCenter(center: Offset(cx, cy), width: carW, height: carH);
    canvas.drawPath(
      bodyPath,
      Paint()..shader = bodyGradient.createShader(bodyRect),
    );

    _drawWindows(canvas, cx, cy, carW, carH);
    _drawWheels(canvas, cx, cy, carW, carH);
    _drawHighlight(canvas, bodyPath);
  }

  Path _buildCarBodyPath(double cx, double cy, double carW, double carH) {
    final path = Path();
    final left = cx - carW / 2;

    path.moveTo(left + carW * 0.08, cy + carH * 0.25);
    path.quadraticBezierTo(left, cy + carH * 0.1, left + carW * 0.12, cy - carH * 0.05);
    path.lineTo(left + carW * 0.28, cy - carH * 0.35);
    path.quadraticBezierTo(left + carW * 0.38, cy - carH * 0.48, left + carW * 0.52, cy - carH * 0.42);
    path.lineTo(left + carW * 0.68, cy - carH * 0.38);
    path.quadraticBezierTo(left + carW * 0.88, cy - carH * 0.32, left + carW * 0.94, cy - carH * 0.05);
    path.quadraticBezierTo(left + carW, cy + carH * 0.15, left + carW * 0.88, cy + carH * 0.28);
    path.quadraticBezierTo(left + carW * 0.5, cy + carH * 0.32, left + carW * 0.08, cy + carH * 0.25);
    path.close();
    return path;
  }

  void _drawWindows(Canvas canvas, double cx, double cy, double carW, double carH) {
    final left = cx - carW / 2;
    final windowColor = tokens.isDark
        ? const Color(0xFF1A1A22).withValues(alpha: 0.9)
        : const Color(0xFF2A3040).withValues(alpha: 0.75);

    final windshield = Path()
      ..moveTo(left + carW * 0.30, cy - carH * 0.08)
      ..lineTo(left + carW * 0.38, cy - carH * 0.35)
      ..lineTo(left + carW * 0.52, cy - carH * 0.32)
      ..lineTo(left + carW * 0.48, cy - carH * 0.05)
      ..close();

    final rear = Path()
      ..moveTo(left + carW * 0.52, cy - carH * 0.32)
      ..lineTo(left + carW * 0.68, cy - carH * 0.28)
      ..lineTo(left + carW * 0.78, cy - carH * 0.05)
      ..lineTo(left + carW * 0.58, cy - carH * 0.05)
      ..close();

    final paint = Paint()..color = windowColor;
    canvas.drawPath(windshield, paint);
    canvas.drawPath(rear, paint);

    final glare = Paint()
      ..color = tokens.carHighlight.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(windshield, glare);
  }

  void _drawWheels(Canvas canvas, double cx, double cy, double carW, double carH) {
    final left = cx - carW / 2;
    final wheelY = cy + carH * 0.18;
    final wheelR = carH * 0.22;

    for (final wx in [left + carW * 0.22, left + carW * 0.72]) {
      canvas.drawCircle(
        Offset(wx, wheelY),
        wheelR,
        Paint()..color = tokens.isDark ? const Color(0xFF0A0A0C) : const Color(0xFF1A1A1E),
      );
      canvas.drawCircle(
        Offset(wx, wheelY),
        wheelR * 0.65,
        Paint()..color = tokens.isDark ? const Color(0xFF3A3A42) : const Color(0xFF888890),
      );
      canvas.drawCircle(
        Offset(wx, wheelY),
        wheelR * 0.2,
        Paint()..color = tokens.accentMuted,
      );
    }
  }

  void _drawHighlight(Canvas canvas, Path bodyPath) {
    final highlight = Paint()
      ..color = tokens.carHighlight.withValues(alpha: tokens.isDark ? 0.08 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(bodyPath, highlight);
  }

  void _drawGlow(Canvas canvas, double w, double h) {
    if (!tokens.isDark) return;
    final cx = w / 2;
    final cy = h * 0.45;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.35);
    final gradient = RadialGradient(
      colors: [
        tokens.glow.withValues(alpha: 0.12),
        Colors.transparent,
      ],
    );
    canvas.drawOval(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _CarHeroPainter oldDelegate) {
    return oldDelegate.tokens != tokens || oldDelegate.bodyColor != bodyColor;
  }
}
