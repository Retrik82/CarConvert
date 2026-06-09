import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';

/// #region agent log
class DebugLog {
  static const _sessionId = 'd819a4';
  static const _ingestPath = '/ingest/926ad504-cc28-45dd-bd18-8be17417dd04';

  static String get _ingestUrl {
    final host = Uri.parse(Env.apiBaseUrl).host;
    return 'http://$host:7534$_ingestPath';
  }

  static void emit(
    String location,
    String message, {
    String? hypothesisId,
    String? runId,
    Map<String, dynamic>? data,
  }) {
    final payload = <String, dynamic>{
      'sessionId': _sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'location': location,
      'message': message,
      if (hypothesisId != null) 'hypothesisId': hypothesisId,
      if (runId != null) 'runId': runId,
      if (data != null) 'data': data,
    };
    debugPrint('[debug-d819a4] $message ${data ?? ''}');
    http
        .post(
          Uri.parse(_ingestUrl),
          headers: {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': _sessionId,
          },
          body: jsonEncode(payload),
        )
        .catchError((_) => http.Response('', 0));
  }
}
/// #endregion
