import '../models/hint_response.dart';
import '../repositories/camera_repository.dart';

/// @deprecated Use [CameraRepository] instead.
class WebSocketService {
  final _repo = CameraRepository();

  Stream<HintResponse> get hints => _repo.hints;
  Stream<String> get status => _repo.status;

  Future<void> connect({required String sessionId, required String token}) =>
      _repo.connect(sessionId: sessionId, token: token);

  void sendFrame(String base64Image, {String mimeType = 'image/jpeg'}) =>
      _repo.sendFrame(base64Image, mimeType: mimeType);

  Future<void> disconnect() => _repo.disconnect();
  void dispose() => _repo.dispose();
}
