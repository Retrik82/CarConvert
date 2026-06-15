import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CameraPreviewFit { contain, cover }

/// Matches [CameraPreview] intrinsic sizing (portrait uses inverted sensor ratio).
double cameraPreviewDisplayAspectRatio(CameraController controller) {
  if (!controller.value.isInitialized) return 9 / 16;
  final sensorRatio = controller.value.aspectRatio;
  if (sensorRatio <= 0) return 9 / 16;
  return _isCameraLandscape(controller) ? sensorRatio : (1 / sensorRatio);
}

bool _isCameraLandscape(CameraController controller) {
  return <DeviceOrientation>[
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ].contains(_cameraApplicableOrientation(controller));
}

DeviceOrientation _cameraApplicableOrientation(CameraController controller) {
  final value = controller.value;
  return value.isRecordingVideo
      ? value.recordingOrientation!
      : (value.previewPauseOrientation ??
          value.lockedCaptureOrientation ??
          value.deviceOrientation);
}

Size fitSizeToAspectRatio({
  required double maxWidth,
  required double maxHeight,
  required double aspectRatio,
}) {
  if (maxWidth <= 0 || maxHeight <= 0 || aspectRatio <= 0) {
    return Size.zero;
  }

  final containerRatio = maxWidth / maxHeight;
  if (containerRatio > aspectRatio) {
    final height = maxHeight;
    return Size(height * aspectRatio, height);
  }

  final width = maxWidth;
  return Size(width, width / aspectRatio);
}

Size coverSizeToAspectRatio({
  required double maxWidth,
  required double maxHeight,
  required double aspectRatio,
}) {
  if (maxWidth <= 0 || maxHeight <= 0 || aspectRatio <= 0) {
    return Size.zero;
  }

  final containerRatio = maxWidth / maxHeight;
  if (containerRatio > aspectRatio) {
    final width = maxWidth;
    return Size(width, width / aspectRatio);
  }

  final height = maxHeight;
  return Size(height * aspectRatio, height);
}

/// Full-bleed or contained [CameraPreview] with optional overlay.
class CameraPreviewView extends StatelessWidget {
  final CameraController controller;
  final Widget? overlay;
  final CameraPreviewFit fit;

  const CameraPreviewView({
    super.key,
    required this.controller,
    this.overlay,
    this.fit = CameraPreviewFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewRatio = cameraPreviewDisplayAspectRatio(controller);
        final previewSize = switch (fit) {
          CameraPreviewFit.contain => fitSizeToAspectRatio(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
              aspectRatio: previewRatio,
            ),
          CameraPreviewFit.cover => coverSizeToAspectRatio(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
              aspectRatio: previewRatio,
            ),
        };

        if (previewSize == Size.zero) {
          return CameraPreview(controller, child: overlay);
        }

        final child = SizedBox(
          width: previewSize.width,
          height: previewSize.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              if (overlay != null) overlay!,
            ],
          ),
        );

        if (fit == CameraPreviewFit.cover) {
          return ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              alignment: Alignment.center,
              child: child,
            ),
          );
        }

        return Center(child: child);
      },
    );
  }
}
