import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../repositories/background_repository.dart';
import '../core/theme/app_tokens.dart';

class AuthenticatedBackgroundImage extends StatefulWidget {
  final String? previewPath;
  final String? presetSlug;
  final String? angle;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AuthenticatedBackgroundImage({
    super.key,
    required this.previewPath,
    this.presetSlug,
    this.angle,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<AuthenticatedBackgroundImage> createState() => _AuthenticatedBackgroundImageState();
}

class _AuthenticatedBackgroundImageState extends State<AuthenticatedBackgroundImage> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedBackgroundImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.previewPath != widget.previewPath ||
        oldWidget.presetSlug != widget.presetSlug ||
        oldWidget.angle != widget.angle) {
      _future = _load();
    }
  }

  Future<Uint8List?> _load() async {
    final path = widget.previewPath;
    if ((path == null || path.isEmpty) &&
        (widget.presetSlug == null || widget.angle == null)) {
      return null;
    }

    try {
      return await BackgroundRepository.instance.fetchImageBytes(
        path ?? '',
        presetSlug: widget.presetSlug,
        angle: widget.angle,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = _placeholder(tokens, showLoader: true);
        } else if (snapshot.hasError || snapshot.data == null) {
          child = _placeholder(tokens);
        } else {
          child = Image.memory(
            snapshot.data!,
            fit: widget.fit,
            alignment: Alignment.center,
            gaplessPlayback: true,
            filterQuality: FilterQuality.high,
          );
        }

        child = SizedBox.expand(child: child);

        if (widget.borderRadius != null) {
          child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
        }
        return child;
      },
    );
  }

  Widget _placeholder(AppTokens tokens, {bool showLoader = false}) {
    return Container(
      color: tokens.surfaceMuted,
      alignment: Alignment.center,
      child: showLoader
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: tokens.textTertiary),
            )
          : Icon(Icons.image_outlined, color: tokens.textTertiary, size: 28),
    );
  }
}
