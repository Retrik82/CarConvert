import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Ratios must match [FrameGuidePainter] and backend `image_utils.FRAME_CROP_*`.
const double frameCropLeft = 0.08;
const double frameCropTop = 0.22;
const double frameCropWidth = 0.84;
const double frameCropHeight = 0.48;

Uint8List cropToFrameGuide(Uint8List bytes, {int quality = 92}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return bytes;
  }
  if (decoded == null) return bytes;

  final left = (decoded.width * frameCropLeft).round();
  final top = (decoded.height * frameCropTop).round();
  final width = (decoded.width * frameCropWidth).round().clamp(1, decoded.width - left);
  final height = (decoded.height * frameCropHeight).round().clamp(1, decoded.height - top);

  final cropped = img.copyCrop(
    decoded,
    x: left,
    y: top,
    width: width,
    height: height,
  );
  return Uint8List.fromList(img.encodeJpg(cropped, quality: quality));
}
