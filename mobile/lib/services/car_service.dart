import 'dart:typed_data';

import '../models/car.dart';
import '../repositories/car_repository.dart';

/// @deprecated Use [CarRepository] instead.
class CarService {
  CarService._();
  static final CarService instance = CarService._();

  final _repo = CarRepository.instance;

  List<Car> get cars => _repo.cars;
  Future<void> load() => _repo.load();
  Future<void> clear() => _repo.clear();
  Car? getById(String id) => _repo.getById(id);
  Future<Car> createCar({String? name}) => _repo.createCar(name: name);
  Future<Car> addRender({
    String? carId,
    required String jobId,
    Uint8List? originalBytes,
    Uint8List? renderedBytes,
    String renderedExt = 'png',
    double? qualityScore,
  }) =>
      _repo.addRender(
        carId: carId,
        jobId: jobId,
        originalBytes: originalBytes,
        renderedBytes: renderedBytes,
        renderedExt: renderedExt,
        qualityScore: qualityScore,
      );
  Future<void> deleteCar(String carId) => _repo.deleteCar(carId);
  Future<void> deleteRender(String carId, String renderId) => _repo.deleteRender(carId, renderId);
  Future<void> updateCarName(String carId, String name) => _repo.updateCarName(carId, name);
}
