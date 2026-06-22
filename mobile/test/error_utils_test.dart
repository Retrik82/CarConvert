import 'package:carconvert/utils/error_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('userFacingError extracts nested API error JSON', () {
    const raw =
        'Exception: Failed to create background: {"success":false,"error":"Background generation failed for angles: front."}';

    expect(
      userFacingError(raw),
      'Background generation failed for angles: front.',
    );
  });
}
