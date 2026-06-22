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
