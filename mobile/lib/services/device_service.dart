import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable device id for multi-device session tracking on the backend.
class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  static const _deviceIdKey = 'device_id';

  String? _cachedId;

  Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    _cachedId = id;
    return id;
  }
}
