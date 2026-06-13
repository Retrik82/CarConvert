import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../models/background.dart';
import 'authenticated_background_image.dart';

/// Rich procedural studio preview for preset backgrounds.
/// Server placeholders are flat gradients — this renders a proper scene.
class BackgroundScenePreview extends StatelessWidget {
  final BackgroundPreset preset;
  final String? angle;
  final bool showCar;
  final BorderRadius? borderRadius;

  const BackgroundScenePreview({
    super.key,
    required this.preset,
    this.angle,
    this.showCar = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (preset.isCustom) {
      final variant = angle != null ? preset.variantByAngle(angle!) : preset.defaultVariant;
      final previewPath = variant?.previewUrl ?? preset.previewUrl;
      return AuthenticatedBackgroundImage(
        previewPath: previewPath,
        borderRadius: borderRadius,
      );
    }

    final child = CustomPaint(
      painter: _ScenePainter(
        slug: preset.slug,
        tokens: context.tokens,
        showCar: showCar,
      ),
      child: const SizedBox.expand(),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }
}

class _ScenePainter extends CustomPainter {
  final String slug;
  final AppTokens tokens;
  final bool showCar;

  _ScenePainter({
    required this.slug,
    required this.tokens,
    required this.showCar,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (slug) {
      case 'gray-showroom':
        _paintShowroom(canvas, size);
        break;
      case 'auto-workshop':
        _paintWorkshop(canvas, size);
        break;
      default:
        _paintGeneric(canvas, size);
    }
    if (showCar) _paintCarSilhouette(canvas, size);
  }

  void _paintShowroom(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFE8E8EC), const Color(0xFFB8B8C0), const Color(0xFF9898A0)],
        ).createShader(bgRect),
    );

    final floorRect = Rect.fromLTWH(0, h * 0.62, w, h * 0.38);
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFD0D0D6), const Color(0xFF909098)],
        ).createShader(floorRect),
    );

    final spotRect = Rect.fromCircle(center: Offset(w * 0.5, h * 0.25), radius: w * 0.45);
    canvas.drawOval(
      spotRect,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.35), Colors.transparent],
        ).createShader(spotRect),
    );

    final podiumW = w * 0.42;
    final podiumH = h * 0.04;
    final podiumX = (w - podiumW) / 2;
    final podiumY = h * 0.68;
    final podium = RRect.fromRectAndRadius(
      Rect.fromLTWH(podiumX, podiumY, podiumW, podiumH),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      podium,
      Paint()..color = const Color(0xFFE0E0E6),
    );
    canvas.drawRRect(
      podium.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawLine(
      Offset(0, h * 0.62),
      Offset(w, h * 0.62),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 1,
    );
  }

  void _paintWorkshop(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgRect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(
      bgRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF3A4555), const Color(0xFF252830), const Color(0xFF1A1E24)],
        ).createShader(bgRect),
    );

    for (var i = 0; i < 4; i++) {
      final x = w * (0.15 + i * 0.22);
      canvas.drawRect(
        Rect.fromLTWH(x - 8, h * 0.04, 16, h * 0.08),
        Paint()..color = const Color(0xFF505868),
      );
      final lightRect = Rect.fromCircle(center: Offset(x, h * 0.1), radius: 14);
      canvas.drawOval(
        lightRect,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFFFFF8E8), const Color(0x40FFF8E8), Colors.transparent],
          ).createShader(lightRect),
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.72, w, h * 0.28),
      Paint()..color = const Color(0xFF3A3A42),
    );

    canvas.drawRect(
      Rect.fromLTWH(w * 0.04, h * 0.28, w * 0.18, h * 0.38),
      Paint()..color = const Color(0xFF4A5568),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.78, h * 0.32, w * 0.16, h * 0.34),
      Paint()..color = const Color(0xFF4A5568),
    );

    canvas.drawRect(
      Rect.fromLTWH(w * 0.08, h * 0.18, 6, h * 0.58),
      Paint()..color = const Color(0xFF606878),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.86, h * 0.18, 6, h * 0.58),
      Paint()..color = const Color(0xFF606878),
    );
  }

  void _paintGeneric(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [tokens.heroAmbient, tokens.heroFloor],
        ).createShader(rect),
    );
  }

  void _paintCarSilhouette(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final cy = h * 0.58;
    final carW = w * 0.52;
    final carH = h * 0.16;

    final path = Path();
    final left = cx - carW / 2;
    path.moveTo(left + carW * 0.08, cy + carH * 0.3);
    path.quadraticBezierTo(left, cy + carH * 0.1, left + carW * 0.12, cy - carH * 0.05);
    path.lineTo(left + carW * 0.28, cy - carH * 0.42);
    path.quadraticBezierTo(left + carW * 0.4, cy - carH * 0.55, left + carW * 0.52, cy - carH * 0.48);
    path.lineTo(left + carW * 0.68, cy - carH * 0.44);
    path.quadraticBezierTo(left + carW * 0.88, cy - carH * 0.38, left + carW * 0.94, cy - carH * 0.05);
    path.quadraticBezierTo(left + carW, cy + carH * 0.18, left + carW * 0.88, cy + carH * 0.32);
    path.close();

    final bodyColor = slug == 'auto-workshop'
        ? const Color(0xFF2A2A32)
        : const Color(0xFFF0F0F4);

    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(bodyColor, Colors.white, 0.2)!,
            bodyColor,
            Color.lerp(bodyColor, Colors.black, 0.15)!,
          ],
        ).createShader(Rect.fromCenter(center: Offset(cx, cy), width: carW, height: carH)),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: slug == 'auto-workshop' ? 0.12 : 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    for (final wx in [left + carW * 0.22, left + carW * 0.72]) {
      canvas.drawCircle(Offset(wx, cy + carH * 0.22), carH * 0.28, Paint()..color = const Color(0xFF1A1A1E));
      canvas.drawCircle(Offset(wx, cy + carH * 0.22), carH * 0.16, Paint()..color = const Color(0xFF666670));
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) {
    return oldDelegate.slug != slug || oldDelegate.showCar != showCar;
  }
}
