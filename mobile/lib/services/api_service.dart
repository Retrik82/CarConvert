import 'dart:typed_data';

import '../models/history_item.dart';
import '../models/process_job.dart';
import '../repositories/photo_repository.dart';
import '../repositories/settings_repository.dart';

/// @deprecated Use [PhotoRepository] and [SettingsRepository] instead.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final _photo = PhotoRepository.instance;
  final _settings = SettingsRepository.instance;

  Future<String> startSession() => _photo.startSession();
  Future<void> wakeServer({int attempts = 3}) => _photo.wakeServer(attempts: attempts);
  Future<ProcessJob> processPhoto(Uint8List bytes, String filename, {String? sessionId}) =>
      _photo.processPhoto(bytes, filename, sessionId: sessionId);
  Future<PhotoResult> getResult(String jobId) => _photo.getResult(jobId);
  Future<List<HistoryItem>> getHistory() => _photo.getHistory();
  Future<double> getGenerationPrice() => _settings.getGenerationPrice();
  Future<double> setGenerationPrice(double priceUsd) => _settings.setGenerationPrice(priceUsd);
}
