import 'package:carconvert/widgets/camera_preview_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fitSizeToAspectRatio', () {
    test('fits tall preview inside portrait container', () {
      final size = fitSizeToAspectRatio(
        maxWidth: 400,
        maxHeight: 700,
        aspectRatio: 9 / 16,
      );

      expect(size.height, closeTo(700, 0.01));
      expect(size.width, closeTo(700 * (9 / 16), 0.01));
      expect(size.width, lessThanOrEqualTo(400));
    });

    test('fits wide preview inside landscape container', () {
      final size = fitSizeToAspectRatio(
        maxWidth: 900,
        maxHeight: 400,
        aspectRatio: 16 / 9,
      );

      expect(size.height, closeTo(400, 0.01));
      expect(size.width, closeTo(400 * (16 / 9), 0.01));
      expect(size.width, lessThanOrEqualTo(900));
    });
  });
}
