import 'dart:io';
import 'dart:typed_data';

import '../datasource/local/car_local_datasource.dart';
import '../datasource/remote/car_remote_datasource.dart';
import '../models/car.dart';
import '../repositories/auth_repository.dart';

class CarRepository {
  CarRepository._() {
    _remote = CarRemoteDataSource(AuthRepository.instance.httpClient);
  }

  static final CarRepository instance = CarRepository._();

  final _local = CarLocalDataSource();
  late final CarRemoteDataSource _remote;
  List<Car> _cars = [];

  List<Car> get cars => List.unmodifiable(_cars);

  bool get _canSync => AuthRepository.instance.isLoggedIn;

  Future<void> load() async {
    if (_canSync) {
      try {
        var remoteCars = await _remote.fetchCars();
        if (remoteCars.isEmpty) {
          await _migrateLocalToServer();
          remoteCars = await _remote.fetchCars();
        }
        await _cacheRemoteCars(remoteCars);
        _cars = await _local.loadCars();
        return;
      } catch (_) {
        // Fall back to local cache when offline or API unavailable.
      }
    }
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
    if (_canSync) {
      final remote = await _remote.createCar(name: name ?? 'My Car');
      _cars.insert(0, remote);
      await _local.saveCars(_cars);
      return remote;
    }

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
    if (_canSync) {
      var targetCarId = carId;
      if (targetCarId == null || getById(targetCarId) == null) {
        final created = await _remote.createCar(name: 'My Car');
        targetCarId = created.id;
      }

      final remoteRender = await _remote.saveRender(
        carId: targetCarId,
        jobId: jobId,
        name: renderName,
        originalBytes: originalBytes,
        renderedBytes: renderedBytes,
        renderedExt: renderedExt,
        qualityScore: qualityScore,
      );

      final files = await _local.saveRenderFiles(
        carId: targetCarId,
        renderId: remoteRender.id,
        originalBytes: originalBytes,
        renderedBytes: renderedBytes,
        renderedExt: renderedExt,
      );

      final render = remoteRender.copyWith(
        originalPath: files.originalPath,
        renderedPath: files.renderedPath,
      );

      final existing = getById(targetCarId);
      final car = existing == null
          ? Car(id: targetCarId, name: 'My Car', createdAt: DateTime.now(), renders: [render])
          : existing.copyWith(renders: [...existing.renders, render]);

      _cars = [
        car,
        ..._cars.where((item) => item.id != car.id),
      ];
      await _local.saveCars(_cars);
      return car;
    }

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
    if (_canSync) {
      await _remote.deleteCar(carId);
    }
    final car = getById(carId);
    if (car != null) {
      await _local.deleteCarFiles(car.id);
    }
    _cars.removeWhere((c) => c.id == carId);
    await _local.saveCars(_cars);
  }

  Future<void> deleteRender(String carId, String renderId) async {
    if (_canSync) {
      await _remote.deleteRender(carId, renderId);
    }
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
    if (_canSync) {
      final remote = await _remote.updateCarName(carId, name);
      _cars = _cars.map((c) => c.id == carId ? c.copyWith(name: remote.name) : c).toList();
      await _local.saveCars(_cars);
      return;
    }
    final car = getById(carId);
    if (car == null) return;
    final updated = car.copyWith(name: name);
    _cars = _cars.map((c) => c.id == carId ? updated : c).toList();
    await _local.saveCars(_cars);
  }

  Future<void> updateRenderName(String carId, String renderId, String name) async {
    if (_canSync) {
      await _remote.updateRenderName(carId: carId, renderId: renderId, name: name);
    }
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

  Future<void> _migrateLocalToServer() async {
    final localCars = await _local.loadCars();
    if (localCars.isEmpty) return;

    for (final car in localCars) {
      final remoteCar = await _remote.createCar(name: car.name);
      for (final render in car.renders) {
        final originalBytes = await _readRenderBytes(render.originalPath);
        final renderedBytes = await _readRenderBytes(render.renderedPath);
        final ext = render.renderedPath?.split('.').last ?? 'png';
        await _remote.saveRender(
          carId: remoteCar.id,
          jobId: render.jobId,
          name: render.name,
          originalBytes: originalBytes,
          renderedBytes: renderedBytes,
          renderedExt: ext,
          qualityScore: render.qualityScore,
        );
      }
    }
    await _local.clearCars();
  }

  Future<void> _cacheRemoteCars(List<Car> remoteCars) async {
    final cachedCars = <Car>[];
    for (final car in remoteCars) {
      final cachedRenders = <RenderResult>[];
      for (final render in car.renders) {
        final originalBytes = render.originalPath != null
            ? await _remote.downloadImage(render.originalPath!)
            : null;
        final renderedBytes = render.renderedPath != null
            ? await _remote.downloadImage(render.renderedPath!)
            : null;
        final ext = render.renderedPath?.endsWith('.jpg') == true ? 'jpg' : 'png';
        final files = await _local.saveRenderFiles(
          carId: car.id,
          renderId: render.id,
          originalBytes: originalBytes,
          renderedBytes: renderedBytes,
          renderedExt: ext,
        );
        cachedRenders.add(render.copyWith(
          originalPath: files.originalPath,
          renderedPath: files.renderedPath,
        ));
      }
      cachedCars.add(car.copyWith(renders: cachedRenders));
    }
    await _local.saveCars(cachedCars);
  }

  Future<Uint8List?> _readRenderBytes(String? path) async {
    if (path == null) return null;
    if (path.startsWith('/')) {
      return _remote.downloadImage(path);
    }
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
