import 'dart:typed_data';

import 'package:flutter/material.dart';

class BeforeAfterSlider extends StatefulWidget {
  final Uint8List beforeBytes;
  final Uint8List afterBytes;

  const BeforeAfterSlider({
    super.key,
    required this.beforeBytes,
    required this.afterBytes,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _position = 0.5;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final dividerX = width * _position;

        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(widget.afterBytes, fit: BoxFit.contain),
              ClipRect(
                clipper: _LeftClipper(dividerX),
                child: Image.memory(widget.beforeBytes, fit: BoxFit.contain),
              ),
              Positioned(
                left: dividerX - 1,
                top: 0,
                bottom: 0,
                child: Container(width: 2, color: Colors.white),
              ),
              Positioned(
                left: dividerX - 18,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.compare_arrows, color: Colors.black, size: 20),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _label('Before'),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _label('After'),
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
        );
      },
    );
  }

  Widget _label(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
