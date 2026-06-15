import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class CameraFrameEncodeRequest {
  final int width;
  final int height;
  final ImageFormatGroup format;
  final List<Uint8List> planeBytes;
  final List<int> bytesPerRow;
  final List<int> bytesPerPixel;
  final int sensorOrientation;
  final int targetWidth;
  final int quality;

  const CameraFrameEncodeRequest({
    required this.width,
    required this.height,
    required this.format,
    required this.planeBytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
    required this.sensorOrientation,
    this.targetWidth = 640,
    this.quality = 65,
  });

  factory CameraFrameEncodeRequest.fromCameraImage(
    CameraImage image, {
    required int sensorOrientation,
    int targetWidth = 640,
    int quality = 65,
  }) {
    return CameraFrameEncodeRequest(
      width: image.width,
      height: image.height,
      format: image.format.group,
      planeBytes: image.planes.map((p) => Uint8List.fromList(p.bytes)).toList(),
      bytesPerRow: image.planes.map((p) => p.bytesPerRow).toList(),
      bytesPerPixel: image.planes.map((p) => p.bytesPerPixel ?? 1).toList(),
      sensorOrientation: sensorOrientation,
      targetWidth: targetWidth,
      quality: quality,
    );
  }
}

Future<Uint8List?> encodeCameraFrameJpeg(
  CameraImage image, {
  required int sensorOrientation,
  int targetWidth = 640,
  int quality = 65,
}) {
  final request = CameraFrameEncodeRequest.fromCameraImage(
    image,
    sensorOrientation: sensorOrientation,
    targetWidth: targetWidth,
    quality: quality,
  );
  return compute(_encodeCameraFrameJpeg, request);
}

Uint8List? _encodeCameraFrameJpeg(CameraFrameEncodeRequest request) {
  final decoded = _decodeCameraFrame(request);
  if (decoded == null) return null;

  final rotated = _applySensorRotation(decoded, request.sensorOrientation);
  final resized = rotated.width <= request.targetWidth
      ? rotated
      : img.copyResize(rotated, width: request.targetWidth);
  return Uint8List.fromList(img.encodeJpg(resized, quality: request.quality));
}

img.Image? _decodeCameraFrame(CameraFrameEncodeRequest request) {
  return switch (request.format) {
    ImageFormatGroup.yuv420 => _decodeYuv420(request),
    ImageFormatGroup.bgra8888 => _decodeBgra8888(request),
    _ => null,
  };
}

img.Image _decodeBgra8888(CameraFrameEncodeRequest request) {
  final plane = request.planeBytes.first;
  final bytesPerRow = request.bytesPerRow.first;
  final image = img.Image(width: request.width, height: request.height);

  for (var y = 0; y < request.height; y++) {
    final rowStart = y * bytesPerRow;
    for (var x = 0; x < request.width; x++) {
      final offset = rowStart + x * 4;
      final b = plane[offset];
      final g = plane[offset + 1];
      final r = plane[offset + 2];
      image.setPixelRgb(x, y, r, g, b);
    }
  }
  return image;
}

img.Image _decodeYuv420(CameraFrameEncodeRequest request) {
  final yPlane = request.planeBytes[0];
  final uPlane = request.planeBytes[1];
  final vPlane = request.planeBytes[2];
  final yRowStride = request.bytesPerRow[0];
  final uvRowStride = request.bytesPerRow[1];
  final uvPixelStride = request.bytesPerPixel[1];
  final image = img.Image(width: request.width, height: request.height);

  for (var y = 0; y < request.height; y++) {
    for (var x = 0; x < request.width; x++) {
      final yIndex = y * yRowStride + x;
      final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
      final yValue = yPlane[yIndex];
      final uValue = uPlane[uvIndex];
      final vValue = vPlane[uvIndex];

      final r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
      final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
          .round()
          .clamp(0, 255);
      final b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);
      image.setPixelRgb(x, y, r, g, b);
    }
  }
  return image;
}

img.Image _applySensorRotation(img.Image source, int sensorOrientation) {
  return switch (sensorOrientation) {
    90 => img.copyRotate(source, angle: 90),
    180 => img.copyRotate(source, angle: 180),
    270 => img.copyRotate(source, angle: 270),
    _ => source,
  };
}
