import '../datasource/local/device_local_datasource.dart';

/// @deprecated Use [DeviceLocalDataSource] via [AuthRepository] instead.
class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  final _local = DeviceLocalDataSource();

  Future<String> getDeviceId() => _local.getDeviceId();
}
