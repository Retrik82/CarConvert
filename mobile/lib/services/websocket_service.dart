import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/env.dart';
import '../models/hint_response.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _hintController = StreamController<HintResponse>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  Stream<HintResponse> get hints => _hintController.stream;
  Stream<String> get status => _statusController.stream;

  Future<void> connect({
    required String sessionId,
    required String token,
  }) async {
    await disconnect();
    final uri = Uri.parse('${Env.wsBaseUrl}/camera/stream?session_id=$sessionId&token=$token');
    _statusController.add('Подключение...');
    _channel = WebSocketChannel.connect(uri);

    _subscription = _channel!.stream.listen(
      (event) {
        try {
          final json = jsonDecode(event as String) as Map<String, dynamic>;
          final type = json['type'] as String?;
          if (type == 'connected') {
            _statusController.add('AI активен');
            return;
          }
          if (type == 'error') {
            _statusController.add(json['message'] as String? ?? 'Ошибка');
            return;
          }
          _hintController.add(HintResponse.fromJson(json));
        } catch (_) {}
      },
      onError: (_) => _statusController.add('Ошибка соединения'),
      onDone: () => _statusController.add('Отключено'),
      cancelOnError: false,
    );
  }

  void sendFrame(String base64Image, {String mimeType = 'image/jpeg'}) {
    _channel?.sink.add(jsonEncode({
      'type': 'frame',
      'image_base64': base64Image,
      'mime_type': mimeType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
  }

  void dispose() {
    disconnect();
    _hintController.close();
    _statusController.close();
  }
}
