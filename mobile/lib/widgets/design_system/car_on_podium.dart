import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'car_assets.dart';
import 'car_overlay.dart';

/// Minimal studio shot: car on a podium only — no floor, lights, or gradients.
enum PodiumStyle {
  theme,
  showroom,
  workshop,
}

class CarOnPodium extends StatelessWidget {
  final CarViewAngle view;
  final AppTokens tokens;
  final Color? bodyColor;
  final PodiumStyle podiumStyle;
  final bool showCar;

  const CarOnPodium({
    super.key,
    required this.view,
    required this.tokens,
    this.bodyColor,
    this.podiumStyle = PodiumStyle.theme,
    this.showCar = true,
  });

  static PodiumStyle styleForBackgroundSlug(String slug) {
    switch (slug) {
      case 'gray-showroom':
        return PodiumStyle.showroom;
      case 'auto-workshop':
        return PodiumStyle.workshop;
      default:
        return PodiumStyle.theme;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
          return const SizedBox.shrink();
        }

        final podiumW = w * 0.68;
        final podiumH = h * 0.055;
        final podiumTop = h * 0.78 - podiumH;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (showCar)
              Positioned.fill(
                child: CarOverlay(
                  view: view,
                  tokens: tokens,
                  bodyColor: bodyColor,
                  style: CarOverlayStyle.hero,
                ),
              ),
            if (showCar)
              Positioned(
                left: (w - podiumW) / 2,
                top: podiumTop,
                width: podiumW,
                height: podiumH,
                child: CustomPaint(
                  painter: _PodiumPainter(
                    tokens: tokens,
                    style: podiumStyle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PodiumPainter extends CustomPainter {
  final AppTokens tokens;
  final PodiumStyle style;

  _PodiumPainter({
    required this.tokens,
    required this.style,
  });

  Color get _topColor {
    switch (style) {
      case PodiumStyle.showroom:
        return const Color(0xFFE4E4EA);
      case PodiumStyle.workshop:
        return const Color(0xFF3A3A44);
      case PodiumStyle.theme:
        return tokens.heroPodium;
    }
  }

  Color get _bottomColor {
    switch (style) {
      case PodiumStyle.showroom:
        return const Color(0xFFC8C8D0);
      case PodiumStyle.workshop:
        return const Color(0xFF2A2A32);
      case PodiumStyle.theme:
        return Color.lerp(tokens.heroPodium, tokens.border, 0.35)!;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(h * 0.22),
    );

    canvas.drawRRect(
      rrect.shift(Offset(0, h * 0.35)),
      Paint()
        ..color = tokens.shadow.withValues(alpha: tokens.isDark ? 0.45 : 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * 0.9),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_topColor, _bottomColor],
        ).createShader(rrect.outerRect),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = tokens.border.withValues(alpha: style == PodiumStyle.workshop ? 0.25 : 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant _PodiumPainter oldDelegate) {
    return oldDelegate.tokens != tokens || oldDelegate.style != style;
  }
}
