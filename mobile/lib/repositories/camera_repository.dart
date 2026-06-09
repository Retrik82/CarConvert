import '../datasource/remote/camera_remote_datasource.dart';
import '../models/hint_response.dart';

class CameraRepository {
  CameraRepository() : _remote = CameraRemoteDataSource();

  final CameraRemoteDataSource _remote;

  Stream<HintResponse> get hints => _remote.hints;
  Stream<String> get status => _remote.status;

  Future<void> connect({required String sessionId, required String token}) =>
      _remote.connect(sessionId: sessionId, token: token);

  void sendFrame(String base64Image, {String mimeType = 'image/jpeg'}) =>
      _remote.sendFrame(base64Image, mimeType: mimeType);

  Future<void> disconnect() => _remote.disconnect();

  void dispose() => _remote.dispose();
}
