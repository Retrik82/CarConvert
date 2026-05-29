class Env {
  static const _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001',
  );

  /// Base URL without trailing slash (e.g. https://carconvert-api.onrender.com).
  static String get apiBaseUrl {
    final trimmed = _rawApiBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// WebSocket origin for /camera/stream (wss on HTTPS, default ports omitted).
  static String get wsBaseUrl {
    final uri = Uri.parse(apiBaseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final defaultPort = scheme == 'wss' ? 443 : 80;
    final hasExplicitPort = uri.hasPort && uri.port != defaultPort;
    if (hasExplicitPort) {
      return '$scheme://${uri.host}:${uri.port}';
    }
    return '$scheme://${uri.host}';
  }
}
