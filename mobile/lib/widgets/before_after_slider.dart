import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';
import 'zoomable_image.dart';

class BeforeAfterSlider extends StatefulWidget {
  final Uint8List beforeBytes;
  final Uint8List afterBytes;
  final String? beforeLabel;
  final String? afterLabel;

  const BeforeAfterSlider({
    super.key,
    required this.beforeBytes,
    required this.afterBytes,
    this.beforeLabel,
    this.afterLabel,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _position = 0.5;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;
    final beforeLabel = widget.beforeLabel ?? s.beforeLabel;
    final afterLabel = widget.afterLabel ?? s.afterLabel;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final dividerX = width * _position;

        return GestureDetector(
          onDoubleTap: () => openFullscreenImage(
            context,
            bytes: widget.afterBytes,
            title: afterLabel,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
              boxShadow: tokens.elevatedShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusHero),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: tokens.textPrimary.withValues(alpha: 0.92),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Center(
                          child: Image.memory(
                            widget.afterBytes,
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                          ),
                        ),
                        ClipRect(
                          clipper: _LeftClipper(dividerX),
                          child: Center(
                            child: Image.memory(
                              widget.beforeBytes,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: dividerX - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2, color: Colors.white.withValues(alpha: 0.9)),
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
                    child: _label(beforeLabel, tokens, gradient: false),
                  ),
                  Positioned(
                    top: DesignTokens.spacing12,
                    right: DesignTokens.spacing12,
                    child: _label(afterLabel, tokens, gradient: true),
                  ),
                  Positioned(
                    bottom: DesignTokens.spacing12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                        ),
                        child: Text(
                          s.pinchToZoom,
                          style: tokens.textStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
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
          ),
        );
      },
    );
  }

  Widget _label(String text, AppTokens tokens, {required bool gradient}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: gradient ? tokens.primaryGradient : null,
        color: gradient ? null : tokens.textPrimary.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
      ),
      child: Text(
        text,
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
