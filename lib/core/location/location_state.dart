// =============================================================================
// Файл:    location_state.dart
// Проект:  ParaFlight
// Версия:  0.6.0
// Цель:    Провайдеры локации и состояния GPX
// Изменения:
//   0.6.0 - Первичная реализация
// =============================================================================

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'dart:isolate';

import 'package:flutter/foundation.dart'; // для compute
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'dart:convert';

import '../preferences/preferences_provider.dart';
import '../../features/flight_detector/presentation/track_config_provider.dart';
import 'background_location_task.dart';

import 'location_entity.dart';
import 'gpx_parse_state.dart';
import 'gpx_parser.dart';

import '../../features/wind/domain/wind_config.dart';

// Новое: импорты для плеера
import 'playback_state.dart';
import 'playback_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'flight_path_state.dart';
import '../../features/flight_detector/presentation/flight_detector_provider.dart';
import '../../features/wind/presentation/wind_provider.dart';

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

// Провайдер для тоггла "Данные эмулятора"
class EmulatorDataNotifier extends StateNotifier<bool> {
  final Ref ref;
  
  EmulatorDataNotifier(this.ref) : super(ref.read(sharedPreferencesProvider).getBool('emulator_data_enabled') ?? false);

  void toggle(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool('emulator_data_enabled', value);
  }
}

final emulatorDataEnabledProvider = StateNotifierProvider<EmulatorDataNotifier, bool>((ref) {
  return EmulatorDataNotifier(ref);
});

// Провайдер реального GPS через Geolocator + FlutterForegroundTask
final realGpsProvider = StreamProvider.autoDispose<LocationEntity>((ref) async* {
  bool serviceEnabled;
  LocationPermission permission;

  // Локальный счетчик прореживания (сбрасывается при перезапуске GPS)
  DateTime? lastRecordTime;

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
  } 
  
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Разрешения на геолокацию отклонены навсегда.');
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    if (permission == LocationPermission.whileInUse) {
      try {
        permission = await Geolocator.requestPermission();
      } catch (e) {
        debugPrint('Ошибка запроса фоновых прав: $e');
      }
    }
  }

  // Пытаемся получить последнюю позицию быстро
  try {
    debugPrint('realGpsProvider: calling getLastKnownPosition');
    final lastPosition = await Geolocator.getLastKnownPosition().timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );
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
  } catch (e) {
    debugPrint('realGpsProvider: getLastKnownPosition threw: $e');
  }

  // Изменение: Инициализация FlutterForegroundTask
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'location_tracking',
      channelName: 'Location Tracking',
      channelDescription: 'Активный трекинг маршрута',
      channelImportance: NotificationChannelImportance.HIGH,
      priority: NotificationPriority.HIGH,
      iconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 5000,
      isOnceEvent: true,
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  final config = ref.read(trackConfigProvider);
  final intervalMs = (config.gpsRecordIntervalSec * 1000).toInt();

  // Сохраняем интервал для фонового изолята
  await FlutterForegroundTask.saveData(key: 'intervalMs', value: intervalMs.toString());

  if (await FlutterForegroundTask.isRunningService) {
    debugPrint('realGpsProvider: Перезапуск Background Service (уже запущен)');
    await FlutterForegroundTask.restartService();
  } else {
    debugPrint('realGpsProvider: Запуск Background Service');
    await FlutterForegroundTask.startService(
      notificationTitle: 'ParaFlight',
      notificationText: 'GPS активен в фоне',
      callback: startCallback,
    );
  }

  // Слушаем порт от фонового изолята
  debugPrint('realGpsProvider: starting receivePort stream');
  final receivePort = FlutterForegroundTask.receivePort;
  if (receivePort == null) {
    throw Exception('Не удалось инициализировать порт связи с фоновым сервисом');
  }

  await for (final data in receivePort) {
    if (data is String) {
      try {
        final map = jsonDecode(data);
        final loc = LocationEntity(
          latitude: map['latitude'],
          longitude: map['longitude'],
          altitude: map['altitude'],
          speed: map['speed'],
          heading: map['heading'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
        );
        debugPrint('RAW GPS POSITION (Background): ${loc.latitude}, ${loc.longitude}, speed: ${loc.speed}');
        
        // ЕДИНЫЙ ЦЕНТР ПРОРЕЖИВАНИЯ (DOWNSAMPLING)
        // Проверяем, прошло ли достаточно времени с последней записи
        if (lastRecordTime == null ||
            loc.timestamp.difference(lastRecordTime).inMilliseconds >= intervalMs) {
          lastRecordTime = loc.timestamp;

          // Прямое обновление трека и детектора без Riverpod-батчинга
          // ОБА получают абсолютно одинаковый прореженный набор точек
          Future.microtask(() {
            final source = ref.read(dataSourceProvider);
            if (source == DataSource.internalGps) {
              ref.read(realGpsTrackProvider.notifier).addPoint(loc);
              final currentWind = ref.read(windProvider);
              final useMath = ref.read(emulatorDataEnabledProvider);
              ref.read(flightDetectorProvider.notifier).updateLocation(loc, false, currentWind, useCalculatedSpeed: useMath);
            }
          });
          
          yield loc;
        } else {
          // Игнорируем промежуточные точки
        }
      } catch (e) {
        debugPrint('Ошибка парсинга данных из фона: $e');
      }
    }
  }

  // При остановке провайдера стопаем сервис
  ref.onDispose(() {
    FlutterForegroundTask.stopService();
  });
}); // конец realGpsProvider

final locationProvider = Provider<AsyncValue<LocationEntity?>>((ref) {
  final dataSource = ref.watch(dataSourceProvider);
  debugPrint('locationProvider update | dataSource: $dataSource');
  
  if (dataSource == DataSource.internalGps) {
    final gpsState = ref.watch(realGpsProvider);
    debugPrint('locationProvider | internalGps state: $gpsState (hasValue: ${gpsState.hasValue}, isLoading: ${gpsState.isLoading})');
    return gpsState;
  } else {
    final gpxState = ref.watch(gpxPointsProvider);
    if (gpxState.hasError) {
      return AsyncValue.error(gpxState.error!, gpxState.stackTrace!);
    }
    final loc = ref.watch(playbackProvider).currentLocation;
    return AsyncValue.data(loc);
  } // конец if
}); // конец locationProvider
