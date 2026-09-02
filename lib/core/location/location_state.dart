// Версия: 0.1.1 | Цель: Провайдеры локации и состояния GPX

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'dart:isolate';

import 'package:flutter/foundation.dart'; // для compute

import '../preferences/preferences_provider.dart';

import 'location_entity.dart';
import 'gpx_parse_state.dart';
import 'gpx_parser.dart';

import '../../features/wind/domain/wind_config.dart';

// Новое: импорты для плеера
import 'playback_state.dart';
import 'playback_notifier.dart';

// Новое: Провайдер для PlaybackNotifier
final playbackProvider = NotifierProvider<PlaybackNotifier, PlaybackState>(() {
  return PlaybackNotifier();
}); // конец playbackProvider

final gpxPointsProvider = StreamProvider<GpxParseState>((ref) async* {
  final xmlString = await rootBundle.loadString('assets/mock_flight.gpx', cache: false);
  const config = WindConfig();
  
  final receivePort = ReceivePort();
  
  await Isolate.spawn(parseGpxStreamingIsolate, {
    'sendPort': receivePort.sendPort,
    'xmlString': xmlString,
    'smoothingWindow': config.gpxSmoothingWindow,
  });

  await for (final message in receivePort) {
    if (message is double) {
      yield GpxParseState(progress: message);
    } else if (message is List<LocationEntity>) {
      yield GpxParseState(progress: 1.0, points: message, isDone: true);
      Future.microtask(() {
        ref.read(playbackProvider.notifier).init(message);
      });
      receivePort.close();
      break;
    } else if (message is Exception || message is Error || message is String) {
      receivePort.close();
      throw Exception(message.toString());
    }
  }
});

// Новое: Перечисление источников данных
enum DataSource { simulator, internalGps }

// Новое: Провайдер текущего источника (всегда стартует с внутреннего GPS)
class DataSourceNotifier extends StateNotifier<DataSource> {
  DataSourceNotifier() : super(DataSource.internalGps);

  void setSource(DataSource source) {
    state = source;
  }
}

final dataSourceProvider = StateNotifierProvider<DataSourceNotifier, DataSource>((ref) {
  return DataSourceNotifier();
});
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
    return ref.watch(realGpsProvider);
  } else {
    final gpxState = ref.watch(gpxPointsProvider);
    if (gpxState.hasError) {
      return AsyncValue.error(gpxState.error!, gpxState.stackTrace!);
    }
    final loc = ref.watch(playbackProvider).currentLocation;
    return AsyncValue.data(loc);
  } // конец if
}); // конец locationProvider
