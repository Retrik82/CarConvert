/// Strips technical prefixes from thrown errors for user-facing UI.
String userFacingError(Object error) {
  final text = error.toString();
  const prefix = 'Exception: ';
  if (text.startsWith(prefix)) {
    return text.substring(prefix.length);
  }
  return text;
}

bool isTimeoutError(Object error) => error.toString().contains('TimeoutException');
