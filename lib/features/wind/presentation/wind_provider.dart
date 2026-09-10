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
// Изменение: Убраны зависимости от flightState и trackConfig
      
      notifier.updateLocationWithLogic(
        timestamp: location.timestamp,
        speed: location.speed,
        heading: location.heading,
        isSimulator: ref.read(dataSourceProvider) == DataSource.simulator,
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

// Изменение: Переменные _isPaused и _activeStartTime удалены

  void updateLocationWithLogic({
    required DateTime timestamp,
    required double speed,
    required double heading,
    required bool isSimulator,
  }) {
    // Изменение: Вся логика "Привратника" (Gatekeeper) удалена. Ветер считается непрерывно.
    
    bool isJump = false;
    // ... дальше идет проверка isJump ...
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
