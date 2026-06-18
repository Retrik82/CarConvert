import 'dart:typed_data';

import '../datasource/local/car_local_datasource.dart';
import '../models/car.dart';

class CarRepository {
  CarRepository._();

  static final CarRepository instance = CarRepository._();

  final _local = CarLocalDataSource();
  List<Car> _cars = [];

  List<Car> get cars => List.unmodifiable(_cars);

  Future<void> load() async {
    _cars = await _local.loadCars();
  }

  Future<void> clear() async {
    _cars = [];
    await _local.clearCars();
  }

  Car? getById(String id) {
    try {
      return _cars.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Car> createCar({String? name}) async {
    final car = await _local.createCar(name: name);
    _cars.insert(0, car);
    await _local.saveCars(_cars);
    return car;
  }

  Future<Car> addRender({
    String? carId,
    required String jobId,
    Uint8List? originalBytes,
    Uint8List? renderedBytes,
    String renderedExt = 'png',
    double? qualityScore,
    String? renderName,
  }) async {
    Car car;
    if (carId != null) {
      car = getById(carId) ?? await createCar();
    } else {
      car = await createCar();
    }

    final files = await _local.saveRenderFiles(
      carId: car.id,
      originalBytes: originalBytes,
      renderedBytes: renderedBytes,
      renderedExt: renderedExt,
    );

    final render = RenderResult(
      id: files.renderId,
      jobId: jobId,
      name: renderName,
      originalPath: files.originalPath,
      renderedPath: files.renderedPath,
      createdAt: DateTime.now(),
      qualityScore: qualityScore,
    );

    final updated = car.copyWith(renders: [...car.renders, render]);
    _cars = _cars.map((c) => c.id == car.id ? updated : c).toList();
    await _local.saveCars(_cars);
    return updated;
  }

  Future<void> deleteCar(String carId) async {
    final car = getById(carId);
    if (car != null) {
      await _local.deleteCarFiles(car.id);
    }
    _cars.removeWhere((c) => c.id == carId);
    await _local.saveCars(_cars);
  }

  Future<void> deleteRender(String carId, String renderId) async {
    final car = getById(carId);
    if (car == null) return;
    final render = car.renders.where((r) => r.id == renderId).firstOrNull;
    if (render != null) {
      await _local.deleteRenderFiles(render.originalPath, render.renderedPath);
    }
    final updated = car.copyWith(
      renders: car.renders.where((r) => r.id != renderId).toList(),
    );
    if (updated.renders.isEmpty) {
      await deleteCar(carId);
    } else {
      _cars = _cars.map((c) => c.id == carId ? updated : c).toList();
      await _local.saveCars(_cars);
    }
  }

  Future<void> updateCarName(String carId, String name) async {
    final car = getById(carId);
    if (car == null) return;
    final updated = car.copyWith(name: name);
    _cars = _cars.map((c) => c.id == carId ? updated : c).toList();
    await _local.saveCars(_cars);
  }

  Future<void> updateRenderName(String carId, String renderId, String name) async {
    final car = getById(carId);
    if (car == null) return;
    final updated = car.copyWith(
      renders: car.renders
          .map((r) => r.id == renderId ? r.copyWith(name: name.trim()) : r)
          .toList(),
    );
    _cars = _cars.map((c) => c.id == carId ? updated : c).toList();
    await _local.saveCars(_cars);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
