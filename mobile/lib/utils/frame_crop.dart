import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

class FrameCropSpec {
  final double left;
  final double top;
  final double width;
  final double height;

  const FrameCropSpec({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

/// Portrait guide — must match backend `image_utils.FRAME_CROP_*`.
const FrameCropSpec portraitFrameCrop = FrameCropSpec(
  left: 0.08,
  top: 0.22,
  width: 0.84,
  height: 0.48,
);

/// Landscape guide — wider frame using more of the short edge.
const FrameCropSpec landscapeFrameCrop = FrameCropSpec(
  left: 0.10,
  top: 0.15,
  width: 0.80,
  height: 0.70,
);

/// Legacy constants kept for tests and backend parity (portrait).
const double frameCropLeft = 0.08;
const double frameCropTop = 0.22;
const double frameCropWidth = 0.84;
const double frameCropHeight = 0.48;

FrameCropSpec frameCropFor(Orientation orientation) {
  return orientation == Orientation.landscape ? landscapeFrameCrop : portraitFrameCrop;
}

FrameCropSpec frameCropForSize(Size size) {
  return size.width > size.height ? landscapeFrameCrop : portraitFrameCrop;
}

/// Display aspect ratio of the frame guide on a given viewport (matches camera overlay).
double frameGuideDisplayAspectRatio(Size viewportSize, FrameCropSpec spec) {
  final cropWidth = viewportSize.width * spec.width;
  final cropHeight = viewportSize.height * spec.height;
  if (cropHeight == 0) return 1;
  return cropWidth / cropHeight;
}

/// Natural width/height of decoded image bytes, or null when decode fails.
double? imageAspectRatio(Uint8List bytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null || decoded.height == 0) return null;
  return decoded.width / decoded.height;
}

Uint8List cropToFrameGuide(
  Uint8List bytes, {
  int quality = 92,
  FrameCropSpec? crop,
}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return bytes;
  }
  if (decoded == null) return bytes;

  decoded = img.bakeOrientation(decoded);

  final spec = crop ?? frameCropForSize(Size(decoded.width.toDouble(), decoded.height.toDouble()));

  final left = (decoded.width * spec.left).round();
  final top = (decoded.height * spec.top).round();
  final width = (decoded.width * spec.width).round().clamp(1, decoded.width - left);
  final height = (decoded.height * spec.height).round().clamp(1, decoded.height - top);

  final cropped = img.copyCrop(
    decoded,
    x: left,
    y: top,
    width: width,
    height: height,
  );
  return Uint8List.fromList(img.encodeJpg(cropped, quality: quality));
}
