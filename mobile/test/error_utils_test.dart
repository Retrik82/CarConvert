import 'package:carconvert/utils/error_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isRetryableUploadFailure', () {
    test('does not retry active job limit', () {
      expect(isRetryableUploadFailure(statusCode: 429), isFalse);
    });

    test('does not retry insufficient balance', () {
      expect(isRetryableUploadFailure(statusCode: 402), isFalse);
    });

    test('retries server errors', () {
      expect(isRetryableUploadFailure(statusCode: 503), isTrue);
    });

    test('retries timeouts', () {
      expect(
        isRetryableUploadFailure(
          statusCode: 0,
          error: Exception('TimeoutException after 0:00:45.000000'),
        ),
        isTrue,
      );
    });
  });
}
