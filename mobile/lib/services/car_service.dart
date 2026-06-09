import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/car.dart';

class CarService {
  CarService._();
  static final CarService instance = CarService._();

  static const _storageKey = 'renderwheels_cars';
  final _uuid = const Uuid();

  List<Car> _cars = [];

  List<Car> get cars => List.unmodifiable(_cars);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      _cars = [];
      return;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    _cars = list.map((e) => Car.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> clear() async {
    _cars = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_cars.map((c) => c.toJson()).toList()),
    );
  }

  Car? getById(String id) {
    try {
      return _cars.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Car> createCar({String? name}) async {
    final car = Car(
      id: _uuid.v4(),
      name: name ?? 'My Car',
      createdAt: DateTime.now(),
    );
    _cars.insert(0, car);
    await _persist();
    return car;
  }

  Future<Car> addRender({
    String? carId,
    required String jobId,
    Uint8List? originalBytes,
    Uint8List? renderedBytes,
    String renderedExt = 'png',
    double? qualityScore,
  }) async {
    Car car;
    if (carId != null) {
      car = getById(carId) ?? await createCar();
    } else {
      car = await createCar();
    }

    final dir = await getApplicationDocumentsDirectory();
    final renderId = _uuid.v4();
    String? originalPath;
    String? renderedPath;

    if (originalBytes != null && originalBytes.isNotEmpty) {
      originalPath = '${dir.path}/cars/${car.id}/$renderId-original.jpg';
      await File(originalPath).create(recursive: true);
      await File(originalPath).writeAsBytes(originalBytes);
    }
    if (renderedBytes != null && renderedBytes.isNotEmpty) {
      renderedPath = '${dir.path}/cars/${car.id}/$renderId-rendered.$renderedExt';
      await File(renderedPath).create(recursive: true);
      await File(renderedPath).writeAsBytes(renderedBytes);
    }

    final render = RenderResult(
      id: renderId,
      jobId: jobId,
      originalPath: originalPath,
      renderedPath: renderedPath,
      createdAt: DateTime.now(),
      qualityScore: qualityScore,
    );

    final updated = car.copyWith(renders: [...car.renders, render]);
    _cars = _cars.map((c) => c.id == car.id ? updated : c).toList();
    await _persist();
    return updated;
  }

  Future<void> deleteCar(String carId) async {
    final car = getById(carId);
    if (car != null) {
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/cars/${car.id}');
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    _cars.removeWhere((c) => c.id == carId);
    await _persist();
  }

  Future<void> deleteRender(String carId, String renderId) async {
    final car = getById(carId);
    if (car == null) return;
    final render = car.renders.where((r) => r.id == renderId).firstOrNull;
    if (render != null) {
      for (final path in [render.originalPath, render.renderedPath]) {
        if (path != null) {
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
      }
    }
    final updated = car.copyWith(
      renders: car.renders.where((r) => r.id != renderId).toList(),
    );
    if (updated.renders.isEmpty) {
      await deleteCar(carId);
    } else {
      _cars = _cars.map((c) => c.id == carId ? updated : c).toList();
      await _persist();
    }
  }

  Future<void> updateCarName(String carId, String name) async {
    final car = getById(carId);
    if (car == null) return;
    final updated = car.copyWith(name: name);
    _cars = _cars.map((c) => c.id == carId ? updated : c).toList();
    await _persist();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
