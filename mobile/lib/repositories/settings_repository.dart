import '../datasource/remote/settings_remote_datasource.dart';
import '../models/pricing_estimate.dart';
import 'auth_repository.dart';

class SettingsRepository {
  SettingsRepository._() {
    _remote = SettingsRemoteDataSource(AuthRepository.instance.httpClient);
  }

  static final SettingsRepository instance = SettingsRepository._();

  late final SettingsRemoteDataSource _remote;

  Future<double> getGenerationPrice() => _remote.getGenerationPrice();

  Future<double> setGenerationPrice(double priceUsd) => _remote.setGenerationPrice(priceUsd);

  Future<double> getCustomBackgroundPrice() => _remote.getCustomBackgroundPrice();

  Future<double> setCustomBackgroundPrice(double priceUsd) => _remote.setCustomBackgroundPrice(priceUsd);

  Future<AdminPricingEstimate> getPricingEstimate() => _remote.getPricingEstimate();
}
