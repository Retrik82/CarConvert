import 'package:carconvert/utils/error_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('userFacingError', () {
    test('strips Exception prefix', () {
      expect(
        userFacingError(Exception('Invalid credentials')),
        'Invalid credentials',
      );
    });

    test('returns plain string unchanged', () {
      expect(userFacingError('Network error'), 'Network error');
    });
  });
}
