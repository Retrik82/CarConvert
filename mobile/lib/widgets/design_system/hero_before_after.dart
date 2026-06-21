import 'package:flutter/material.dart';

import '../../core/assets/bundled_assets.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/design_tokens.dart';
import 'car_assets.dart';
import 'car_overlay.dart';

/// Before/after slider — same BMW M4 overlay on both sides, only background changes.
class HeroBeforeAfter extends StatefulWidget {
  final double height;
  final String? afterPresetSlug;

  const HeroBeforeAfter({
    super.key,
    this.height = 240,
    this.afterPresetSlug,
  });

  @override
  State<HeroBeforeAfter> createState() => _HeroBeforeAfterState();
}

class _HeroBeforeAfterState extends State<HeroBeforeAfter> {
  double _position = 0.5;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final beforeBg = BundledAssets.sliderBeforeBackground;
    final afterBg = BundledAssets.sliderAfterBackgroundForPreset(widget.afterPresetSlug);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final dividerX = width * _position;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
            boxShadow: tokens.elevatedShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _AlignedScene(
                  backgroundPath: afterBg,
                  tokens: tokens,
                  dim: false,
                ),
                ClipRect(
                  clipper: _LeftClipper(dividerX),
                  child: _AlignedScene(
                    backgroundPath: beforeBg,
                    tokens: tokens,
                    dim: true,
                  ),
                ),
                Positioned(
                  left: dividerX - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: Colors.white.withValues(alpha: 0.92)),
                ),
                Positioned(
                  left: dividerX - 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tokens.shadow.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.compare_arrows_rounded, color: tokens.textPrimary, size: 20),
                    ),
                  ),
                ),
                Positioned(
                  top: DesignTokens.spacing12,
                  left: DesignTokens.spacing12,
                  child: _Badge(label: s.beforeLabel, tokens: tokens, gradient: false),
                ),
                Positioned(
                  top: DesignTokens.spacing12,
                  right: DesignTokens.spacing12,
                  child: _Badge(label: s.afterLabel, tokens: tokens, gradient: true),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _position = (_position + details.delta.dx / width).clamp(0.05, 0.95);
                    });
                  },
                  onTapDown: (details) {
                    setState(() {
                      _position = (details.localPosition.dx / width).clamp(0.05, 0.95);
                    });
                  },
                  child: Container(color: Colors.transparent),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Background + identical car placement for perfect before/after alignment.
class _AlignedScene extends StatelessWidget {
  final String backgroundPath;
  final AppTokens tokens;
  final bool dim;

  const _AlignedScene({
    required this.backgroundPath,
    required this.tokens,
    required this.dim,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(backgroundPath, fit: BoxFit.cover),
        if (dim) Container(color: tokens.textPrimary.withValues(alpha: 0.1)),
        CarOverlay(
          view: CarViewAngle.threeQuarterRight,
          tokens: tokens,
          style: CarOverlayStyle.backgroundPreview,
          variant: CarPaintVariant.black,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final AppTokens tokens;
  final bool gradient;

  const _Badge({
    required this.label,
    required this.tokens,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient ? tokens.primaryGradient : null,
        color: gradient ? null : tokens.textPrimary.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
      ),
      child: Text(
        label,
        style: tokens.textStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  final double width;

  _LeftClipper(this.width);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, width, size.height);

  @override
  bool shouldReclip(_LeftClipper oldClipper) => oldClipper.width != width;
}
