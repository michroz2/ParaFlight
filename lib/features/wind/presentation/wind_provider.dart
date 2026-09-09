// =============================================================================
// Файл:    wind_provider.dart
// Проект:  ParaFlight
// Версия:  0.2.0
// Цель:    Провайдер ветра
// Изменения:
//   0.2.0 - Первичная реализация
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/location/location_state.dart';
import '../../../core/location/location_entity.dart';
import '../domain/wind_models.dart';
import '../application/wind_pipeline.dart'; // Восстановленный импорт

import '../../flight_detector/presentation/flight_detector_provider.dart';
import '../../flight_detector/domain/flight_state.dart';
import '../../flight_detector/presentation/track_config_provider.dart';
import '../../settings/application/wind_config_provider.dart';

final StateNotifierProvider<WindNotifier, WindCalculationResult?> windProvider = StateNotifierProvider<WindNotifier, WindCalculationResult?>((ref) {
  final config = ref.watch(windConfigProvider);
  final pipeline = WindPipeline(config: config);
  
  final notifier = WindNotifier(
    pipeline: pipeline,
    getPoints: () => ref.read(playbackProvider.notifier).points,
    getCurrentIndex: () => ref.read(playbackProvider).currentIndex,
  );
  
  // Подписываемся на изменения геолокации
  ref.listen(locationProvider, (previous, asyncLocation) {
    final location = asyncLocation.valueOrNull;
    
    if (location != null) {
      final flightState = ref.read(flightDetectorProvider).state;
      final trackConfig = ref.read(trackConfigProvider);
      
      notifier.updateLocationWithLogic(
        timestamp: location.timestamp,
        speed: location.speed,
        heading: location.heading,
        isSimulator: ref.read(dataSourceProvider) == DataSource.simulator,
        flightState: flightState,
        cfvMinFlightSog: trackConfig.cfvMinFlightSog,
      );
    }
  });

  // Подписываемся на смену источника данных
  ref.listen(dataSourceProvider, (previous, next) {
    if (previous != next) {
      notifier.clear();
    } // конец if
  });

  return notifier;
});

class WindNotifier extends StateNotifier<WindCalculationResult?> {
  final WindPipeline _pipeline;
  final List<LocationEntity> Function() _getPoints;
  final int Function() _getCurrentIndex;
  DateTime? _lastTimestamp;

  WindNotifier({
    required this._pipeline,
    required this._getPoints,
    required this._getCurrentIndex,
  })  : super(null);

  void clear() {
    _pipeline.reset();
    _lastTimestamp = null;
    state = null;
  } // конец метода clear

  bool _isPaused = false;
  DateTime? _activeStartTime;

  void updateLocationWithLogic({
    required DateTime timestamp,
    required double speed,
    required double heading,
    required bool isSimulator,
    required FlightState flightState,
    required double cfvMinFlightSog,
  }) {
    if (flightState == FlightState.inFlight) {
      _isPaused = false;
      _activeStartTime = null; // сброс таймера таймаута
    } else {
      // Логика запуска на земле (поиск Mid-Air Start)
      if (_isPaused) {
        if (speed < 1.0) { // SOG упал к нулю (менее 1 м/с) - сбрасываем блокировку
          _isPaused = false;
          _activeStartTime = null;
        }
      } else {
        if (speed > cfvMinFlightSog) {
          _activeStartTime ??= timestamp;
          // Если мы едем больше 3 минут и не взлетели - это машина, пауза
          if (timestamp.difference(_activeStartTime!).inSeconds > 180) {
            _isPaused = true;
            clear();
            return;
          }
        } else {
          // Если скорость упала, сбрасываем таймер
          _activeStartTime = null;
          clear();
          return;
        }
      }
    }

    if (_isPaused) return;

    bool isJump = false;
    if (_lastTimestamp != null) {
      final diff = timestamp.difference(_lastTimestamp!).inMilliseconds;
      if (diff < 0 || diff > 2000) {
        isJump = true;
      }
    }
    _lastTimestamp = timestamp;

    if (isJump) {
      _pipeline.reset();
      
      WindCalculationResult? latestResult;
      
      if (isSimulator) {
        final allPoints = _getPoints();
        final currentIndex = _getCurrentIndex();
        
        if (allPoints.isNotEmpty && currentIndex >= 0 && currentIndex < allPoints.length) {
          final endTime = allPoints[currentIndex].timestamp;
          final startTime = endTime.subtract(Duration(seconds: _pipeline.config.windowSizeSec.toInt()));
          
          for (int i = 0; i <= currentIndex; i++) {
            final p = allPoints[i];
            if (p.timestamp.isAfter(startTime) || p.timestamp.isAtSameMomentAs(startTime)) {
              final res = _pipeline.processLocation(p.timestamp, p.speed, p.heading);
              if (res != null) latestResult = res;
            }
          }
        }
      }
      
      state = latestResult;
    } else {
      final result = _pipeline.processLocation(timestamp, speed, heading);
      if (result != null) {
        state = result;
      }
    }
  } // конец метода updateLocationWithLogic
} // конец класса WindNotifier
