import '../datasource/remote/background_remote_datasource.dart';
import '../models/background.dart';
import 'auth_repository.dart';

class BackgroundRepository {
  BackgroundRepository._() {
    _remote = BackgroundRemoteDataSource(AuthRepository.instance.httpClient);
  }

  static final BackgroundRepository instance = BackgroundRepository._();

  late final BackgroundRemoteDataSource _remote;

  SelectedBackground? _selected;

  SelectedBackground? get selected => _selected;

  void select(BackgroundPreset preset, BackgroundVariant variant) {
    _selected = SelectedBackground(preset: preset, variant: variant);
  }

  void clearSelection() {
    _selected = null;
  }

  Future<BackgroundCatalog> fetchCatalog() => _remote.fetchCatalog();

  Future<BackgroundPreset> createCustomBackground({
    required String name,
    required String prompt,
  }) =>
      _remote.createCustomBackground(name: name, prompt: prompt);

  Future<List<int>> fetchImageBytes(String previewPath) async {
    final bytes = await _remote.fetchImageBytes(previewPath);
    return bytes;
  }
}
