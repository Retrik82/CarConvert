import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/env.dart';
import '../repositories/background_repository.dart';
import '../theme/app_theme.dart';

class AuthenticatedBackgroundImage extends StatelessWidget {
  final String? previewPath;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AuthenticatedBackgroundImage({
    super.key,
    required this.previewPath,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (previewPath == null || previewPath!.isEmpty) {
      return _placeholder();
    }

    return FutureBuilder<Uint8List>(
      future: BackgroundRepository.instance
          .fetchImageBytes(previewPath!)
          .then((bytes) => Uint8List.fromList(bytes)),
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = _placeholder(showLoader: true);
        } else if (snapshot.hasError || !snapshot.hasData) {
          child = _placeholder();
        } else {
          child = Image.memory(snapshot.data!, fit: fit, width: double.infinity, height: double.infinity);
        }

        if (borderRadius != null) {
          child = ClipRRect(borderRadius: borderRadius!, child: child);
        }
        return child;
      },
    );
  }

  Widget _placeholder({bool showLoader = false}) {
    return Container(
      color: AppTheme.surfaceMuted,
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.image_outlined, color: AppTheme.textTertiary, size: 28),
    );
  }
}

String backgroundPreviewUrl(String? previewPath) {
  if (previewPath == null) return '';
  if (previewPath.startsWith('http')) return previewPath;
  return '${Env.apiBaseUrl}$previewPath';
}
