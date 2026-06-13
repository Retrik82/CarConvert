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

  @override
  void initState() {
    super.initState();
    _future = CarAssetRepository.instance.fetchImageBytes(widget.imagePath);
  }

  @override
  void didUpdateWidget(covariant RemoteCarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _future = CarAssetRepository.instance.fetchImageBytes(widget.imagePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: tokens.textTertiary),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Icon(Icons.directions_car_outlined, color: tokens.textTertiary, size: 32);
        }

        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          alignment: widget.alignment,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          color: widget.tintColor,
          colorBlendMode: widget.tintColor != null ? BlendMode.modulate : null,
        );
      },
    );
  }
}
