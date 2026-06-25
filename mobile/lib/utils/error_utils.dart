import 'dart:convert';

/// Strips technical prefixes from thrown errors for user-facing UI.
String userFacingError(Object error) {
  var text = error.toString();
  const prefix = 'Exception: ';
  if (text.startsWith(prefix)) {
    text = text.substring(prefix.length);
  }

  final jsonStart = text.indexOf('{');
  if (jsonStart >= 0) {
    try {
      final json = jsonDecode(text.substring(jsonStart)) as Map<String, dynamic>;
      final apiError = json['error'] ?? json['detail'];
      if (apiError != null && apiError.toString().trim().isNotEmpty) {
        return apiError.toString();
      }
    } catch (_) {}
  }

  const failedPrefix = 'Failed to create background: ';
  if (text.startsWith(failedPrefix)) {
    return userFacingError(text.substring(failedPrefix.length));
  }

  return text;
}

bool isTimeoutError(Object error) => error.toString().contains('TimeoutException');

/// HTTP statuses that must not be retried (client/backpressure errors).
bool isNonRetryableHttpStatus(int statusCode) {
  return statusCode == 429 ||
      statusCode == 402 ||
      statusCode == 400 ||
      statusCode == 401 ||
      statusCode == 403 ||
      statusCode == 404 ||
      statusCode == 408 ||
      statusCode == 413 ||
      statusCode == 415;
}

bool isRetryableUploadFailure({required int statusCode, Object? error}) {
  if (statusCode > 0 && isNonRetryableHttpStatus(statusCode)) return false;
  if (statusCode >= 500) return true;
  if (error != null && isTimeoutError(error)) return true;
  final text = error?.toString() ?? '';
  return text.contains('connection abort') ||
      text.contains('Connection refused') ||
      text.contains('Failed host lookup') ||
      text.contains('SocketException');
}
