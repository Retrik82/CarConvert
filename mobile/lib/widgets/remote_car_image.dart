import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../repositories/car_asset_repository.dart';

class RemoteCarImage extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;
  final Alignment alignment;
  final Color? tintColor;

  const RemoteCarImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.bottomCenter,
    this.tintColor,
  });

  @override
  State<RemoteCarImage> createState() => _RemoteCarImageState();
}

class _RemoteCarImageState extends State<RemoteCarImage> {
  late Future<Uint8List> _future;
  Uint8List? _cachedBytes;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant RemoteCarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _cachedBytes = null;
      _future = _load();
    }
  }

  Future<Uint8List> _load() {
    return CarAssetRepository.instance.fetchImageBytes(widget.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _cachedBytes = snapshot.data;
        }

        final bytes = snapshot.data ?? _cachedBytes;
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: widget.fit,
            alignment: widget.alignment,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            color: widget.tintColor,
            colorBlendMode: widget.tintColor != null ? BlendMode.modulate : null,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: tokens.textTertiary),
            ),
          );
        }

        return Icon(Icons.directions_car_outlined, color: tokens.textTertiary, size: 32);
      },
    );
  }
}
