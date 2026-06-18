import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';
import '../core/theme/app_tokens.dart';
import '../core/theme/design_tokens.dart';

/// Centered image with pinch-to-zoom. Dark backdrop keeps the car as the focal point.
class ZoomableImage extends StatelessWidget {
  final Uint8List? bytes;
  final String? filePath;
  final double minScale;
  final double maxScale;
  final bool showZoomHint;

  const ZoomableImage({
    super.key,
    this.bytes,
    this.filePath,
    this.minScale = 1.0,
    this.maxScale = 4.0,
    this.showZoomHint = true,
  }) : assert(bytes != null || filePath != null);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final s = context.strings;

    Widget image;
    if (bytes != null) {
      image = Image.memory(bytes!, fit: BoxFit.contain, alignment: Alignment.center);
    } else {
      image = Image.file(File(filePath!), fit: BoxFit.contain, alignment: Alignment.center);
    }

    return Container(
      color: tokens.textPrimary.withValues(alpha: 0.92),
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: minScale,
            maxScale: maxScale,
            alignment: Alignment.center,
            child: Center(child: image),
          ),
          if (showZoomHint)
            Positioned(
              bottom: DesignTokens.spacing12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_out_map_rounded, size: 14, color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(width: 6),
                      Text(
                        s.pinchToZoom,
                        style: tokens.textStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> openFullscreenImage(
  BuildContext context, {
  Uint8List? bytes,
  String? filePath,
  String? title,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (ctx) => _FullscreenImagePage(bytes: bytes, filePath: filePath, title: title),
    ),
  );
}

class _FullscreenImagePage extends StatelessWidget {
  final Uint8List? bytes;
  final String? filePath;
  final String? title;

  const _FullscreenImagePage({this.bytes, this.filePath, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: title != null ? Text(title!, style: const TextStyle(color: Colors.white)) : null,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ZoomableImage(bytes: bytes, filePath: filePath, showZoomHint: true),
    );
  }
}
