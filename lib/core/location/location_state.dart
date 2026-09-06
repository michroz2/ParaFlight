// Версия: 0.6.0 | Цель: Провайдеры локации и состояния GPX

import 'dart:io';

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
import 'package:shared_preferences/shared_preferences.dart';

// Новое: Провайдер выбранного GPX файла
final selectedGpxFileProvider = StateNotifierProvider<SelectedGpxFileNotifier, String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SelectedGpxFileNotifier(prefs);
});

class SelectedGpxFileNotifier extends StateNotifier<String?> {
  final SharedPreferences _prefs;
  static const _key = 'selected_gpx_file';

  SelectedGpxFileNotifier(this._prefs) : super(_prefs.getString(_key));

  void setFile(String path) {
    state = path;
    _prefs.setString(_key, path);
  }
}

// Провайдер для PlaybackNotifier
final playbackProvider = NotifierProvider<PlaybackNotifier, PlaybackState>(() {
  return PlaybackNotifier();
}); // конец playbackProvider

final gpxPointsProvider = StreamProvider<GpxParseState>((ref) async* {
  final filePath = ref.watch(selectedGpxFileProvider);
  
  // Сбрасываем плеер при смене трека
  Future.microtask(() {
    ref.read(playbackProvider.notifier).reset();
  });

  if (filePath == null || filePath.isEmpty) {
    yield GpxParseState(progress: 0.0);
    return;
  } // конец if
  
  final file = File(filePath);
  if (!await file.exists()) {
    throw Exception('Файл трека не найден: $filePath');
  } // конец if

  final xmlString = await file.readAsString();
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
  } // конец for
}); // конец gpxPointsProvider

// Перечисление источников данных
enum DataSource { simulator, internalGps }

// Провайдер текущего источника (всегда стартует с внутреннего GPS)
class DataSourceNotifier extends StateNotifier<DataSource> {
  DataSourceNotifier() : super(DataSource.internalGps);

  void setSource(DataSource source) {
    state = source;
  }
}

final dataSourceProvider = StateNotifierProvider<DataSourceNotifier, DataSource>((ref) {
  return DataSourceNotifier();
});

// Провайдер реального GPS через Geolocator
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

  LocationSettings locationSettings;
  
  if (defaultTargetPlatform == TargetPlatform.android) {
    locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      forceLocationManager: true,
      intervalDuration: const Duration(seconds: 1),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "Запись трека и геоданных",
        notificationTitle: "ParaFlight Трекинг",
        enableWakeLock: true,
      ),
    );
  } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
    locationSettings = AppleSettings(
      accuracy: LocationAccuracy.high,
      activityType: ActivityType.fitness,
      distanceFilter: 0,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
    );
  } else {
    locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  try {
    final lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null) {
      yield LocationEntity(
        latitude: lastPosition.latitude,
        longitude: lastPosition.longitude,
        altitude: lastPosition.altitude,
        speed: lastPosition.speed,
        heading: lastPosition.heading,
        timestamp: lastPosition.timestamp ?? DateTime.now(),
      );
    }
  } catch (_) {
    // Игнорируем ошибку получения последней позиции
  }

  yield* Geolocator.getPositionStream(
    locationSettings: locationSettings,
  ).map((Position position) {
    debugPrint('RAW GPS POSITION: \${position.latitude}, \${position.longitude}, speed: \${position.speed}');
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

// locationProvider теперь возвращает AsyncValue, чтобы UI видел ошибки (например, если нет прав)
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
