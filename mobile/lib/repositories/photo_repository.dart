import 'dart:typed_data';

import '../datasource/remote/photo_remote_datasource.dart';
import '../models/history_item.dart';
import '../models/process_job.dart';
import 'auth_repository.dart';

class PhotoRepository {
  PhotoRepository._() {
    _remote = PhotoRemoteDataSource(AuthRepository.instance.httpClient);
  }

  static final PhotoRepository instance = PhotoRepository._();

  late final PhotoRemoteDataSource _remote;

  Future<void> wakeServer({int attempts = 3}) =>
      AuthRepository.instance.httpClient.wakeServer(
        attempts: attempts,
        requestTimeout: const Duration(seconds: 60),
        required: true,
      );

  Future<String> startSession() => _remote.startSession();

  Future<ProcessJob> processPhoto(
    Uint8List bytes,
    String filename, {
    String? sessionId,
    String? backgroundPresetId,
    String? backgroundPresetSlug,
    String? userBackgroundId,
  }) =>
      _remote.processPhoto(
        bytes,
        filename,
        sessionId: sessionId,
        backgroundPresetId: backgroundPresetId,
        backgroundPresetSlug: backgroundPresetSlug,
        userBackgroundId: userBackgroundId,
      );

  Future<PhotoResult> getResult(String jobId) => _remote.getResult(jobId);

  Future<List<HistoryItem>> getHistory() => _remote.getHistory();
}
