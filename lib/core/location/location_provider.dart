import 'location_entity.dart';

/// Базовый интерфейс для провайдеров геолокации (GPS, BLE, Симулятор)
abstract class LocationProvider {
  /// Поток с данными геолокации
  Stream<LocationEntity> get locationStream;
}
