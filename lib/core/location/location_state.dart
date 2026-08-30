import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'location_entity.dart';
import 'location_provider.dart';
import 'simulator_location_provider.dart';

/// Тестовые данные для симулятора (хардкод из 4 точек полета)
final List<LocationEntity> _testFlightPoints = [
  LocationEntity(
    latitude: 55.751244,
    longitude: 37.618423,
    altitude: 150.0,
    speed: 12.5,
    heading: 90.0,
    timestamp: DateTime.now(),
  ),
  LocationEntity(
    latitude: 55.751500,
    longitude: 37.618900,
    altitude: 152.0,
    speed: 13.0,
    heading: 92.0,
    timestamp: DateTime.now().add(const Duration(seconds: 2)),
  ),
  LocationEntity(
    latitude: 55.751800,
    longitude: 37.619500,
    altitude: 155.0,
    speed: 13.2,
    heading: 95.0,
    timestamp: DateTime.now().add(const Duration(seconds: 5)),
  ),
  LocationEntity(
    latitude: 55.752100,
    longitude: 37.620200,
    altitude: 158.0,
    speed: 13.5,
    heading: 98.0,
    timestamp: DateTime.now().add(const Duration(seconds: 7)),
  ),
];

/// Провайдер, предоставляющий конкретную реализацию интерфейса LocationProvider
final locationProviderType = Provider<LocationProvider>((ref) {
  return SimulatorLocationProvider(_testFlightPoints);
});

/// Провайдер потока данных геолокации, который слушает интерфейс
final locationStreamProvider = StreamProvider<LocationEntity>((ref) {
  final locationProvider = ref.watch(locationProviderType);
  return locationProvider.locationStream;
});
