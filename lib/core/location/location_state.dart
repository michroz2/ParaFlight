// Версия: 0.1.1 | Цель: Провайдеры локации и состояния GPX

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';

import 'package:flutter/foundation.dart'; // для compute

import '../preferences/preferences_provider.dart';

import 'location_entity.dart';
import 'gpx_parser.dart';

import '../../features/wind/domain/wind_config.dart';

// Новое: импорты для плеера
import 'playback_state.dart';
import 'playback_notifier.dart';

// Новое: Провайдер для PlaybackNotifier
final playbackProvider = NotifierProvider<PlaybackNotifier, PlaybackState>(() {
  return PlaybackNotifier();
}); // конец playbackProvider

final gpxPointsProvider = FutureProvider<List<LocationEntity>>((ref) async {
  // Загружаем файл с явным отключением кэширования
  final xmlString = await rootBundle.loadString('assets/mock_flight.gpx', cache: false);
  const config = WindConfig();
  
  // Изменение: Выносим парсинг в отдельный Isolate (фоновый поток), чтобы не блочить UI
  final points = await compute(parseGpxInIsolate, {
    'xmlString': xmlString,
    'smoothingWindow': config.gpxSmoothingWindow,
  });
  // Изменение: инициализируем плеер
  Future.microtask(() {
    ref.read(playbackProvider.notifier).init(points);
  }); // конец микротаска
  return points;
}); // конец gpxPointsProvider

// Новое: Перечисление источников данных
enum DataSource { simulator, internalGps }

// Новое: Провайдер текущего источника с персистентностью
class DataSourceNotifier extends StateNotifier<DataSource> {
  final Ref ref;

  DataSourceNotifier(this.ref) : super(_parse(ref.read(sharedPreferencesProvider).getString('data_source'))) {}

  static DataSource _parse(String? value) {
    if (value == DataSource.internalGps.name) return DataSource.internalGps;
    return DataSource.simulator;
  } // конец метода _parse

  void setSource(DataSource source) {
    state = source;
    ref.read(sharedPreferencesProvider).setString('data_source', source.name);
  } // конец метода setSource
} // конец класса DataSourceNotifier

final dataSourceProvider = StateNotifierProvider<DataSourceNotifier, DataSource>((ref) {
  return DataSourceNotifier(ref);
}); // конец dataSourceProvider

// Новое: Провайдер реального GPS через Geolocator
final realGpsProvider = StreamProvider<LocationEntity>((ref) async* {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Службы геолокации отключены.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('Разрешения на геолокацию отклонены.');
    }
  } // конец if
  
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Разрешения на геолокацию отклонены навсегда.');
  } // конец if

  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    ),
  ).map((Position position) {
    return LocationEntity(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: position.speed, // в м/с
      heading: position.heading, // в градусах
      timestamp: position.timestamp ?? DateTime.now(),
    );
  }); // конец map
}); // конец realGpsProvider

// Изменение: locationProvider теперь возвращает AsyncValue, чтобы UI видел ошибки (например, если нет прав)
final locationProvider = Provider<AsyncValue<LocationEntity?>>((ref) {
  final dataSource = ref.watch(dataSourceProvider);
  
  if (dataSource == DataSource.internalGps) {
    // Пробрасываем состояния загрузки и ошибок от Geolocator
    return ref.watch(realGpsProvider);
  } else {
    // Симулятор всегда отдает синхронные данные
    final loc = ref.watch(playbackProvider).currentLocation;
    return AsyncValue.data(loc);
  } // конец if
}); // конец locationProvider
