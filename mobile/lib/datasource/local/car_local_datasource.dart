import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/car.dart';

class CarLocalDataSource {
  static const _storageKey = 'autocut_cars';
  static const _legacyStorageKey = 'renderwheels_cars';
  final _uuid = const Uuid();

  Future<List<Car>> loadCars() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getString(_storageKey);
    if (raw == null) {
      final legacy = prefs.getString(_legacyStorageKey);
      if (legacy != null) {
        await prefs.setString(_storageKey, legacy);
        await prefs.remove(_legacyStorageKey);
        raw = legacy;
      }
    }
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Car.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveCars(List<Car> cars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(cars.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> clearCars() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<Car> createCar({String? name, String? id}) async {
    return Car(
      id: id ?? _uuid.v4(),
      name: name ?? 'My Car',
      createdAt: DateTime.now(),
    );
  }

  Future<({String? originalPath, String? renderedPath, String renderId})> saveRenderFiles({
    required String carId,
    String? renderId,
    Uint8List? originalBytes,
    Uint8List? renderedBytes,
    String renderedExt = 'png',
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final resolvedRenderId = renderId ?? _uuid.v4();
    String? originalPath;
    String? renderedPath;

    if (originalBytes != null && originalBytes.isNotEmpty) {
      originalPath = '${dir.path}/cars/$carId/$resolvedRenderId-original.jpg';
      await File(originalPath).create(recursive: true);
      await File(originalPath).writeAsBytes(originalBytes);
    }
    if (renderedBytes != null && renderedBytes.isNotEmpty) {
      renderedPath = '${dir.path}/cars/$carId/$resolvedRenderId-rendered.$renderedExt';
      await File(renderedPath).create(recursive: true);
      await File(renderedPath).writeAsBytes(renderedBytes);
    }

    return (originalPath: originalPath, renderedPath: renderedPath, renderId: resolvedRenderId);
  }

  Future<void> deleteCarFiles(String carId) async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/cars/$carId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> deleteRenderFiles(String? originalPath, String? renderedPath) async {
    for (final path in [originalPath, renderedPath]) {
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
  }

  Future<Uint8List?> readFileBytes(String? path) async {
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}
