import 'dart:typed_data';

import 'package:carconvert/utils/frame_crop.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('cropToFrameGuide', () {
    test('crops image to frame ratios', () {
      final source = img.Image(width: 1000, height: 800);
      img.fill(source, color: img.ColorRgb8(255, 0, 0));
      final input = Uint8List.fromList(img.encodeJpg(source));

      final output = cropToFrameGuide(input);
      final decoded = img.decodeImage(output);

      expect(decoded, isNotNull);
      expect(decoded!.width, (1000 * frameCropWidth).round());
      expect(decoded.height, (800 * frameCropHeight).round());
    });

    test('returns original bytes when decode fails', () {
      final invalid = Uint8List.fromList([1, 2, 3, 4]);
      expect(cropToFrameGuide(invalid), invalid);
    });
  });
}
