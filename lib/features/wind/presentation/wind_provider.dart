// =============================================================================
// Файл:    wind_provider.dart
// Проект:  ParaFlight
// Версия:  1.20.5
// Цель:    Провайдер ветра
// Изменения:
//   0.2.0 - Первичная реализация
//   1.20.2 - Улучшен расчет амбиентного ветра. Собирается Минимальный рабочий буфер. Если расчеты дают некорректные ошибки, буфер очищается.
//   1.20.4 - Замена состояния на WindState
//   1.20.5 - Замена isStale на isValid
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/location/location_state.dart';
import '../../../core/location/location_entity.dart';
import '../domain/wind_models.dart';
import '../application/wind_pipeline.dart'; // Восстановленный импорт

import '../../settings/application/wind_config_provider.dart';

final StateNotifierProvider<WindNotifier, WindState> windProvider = StateNotifierProvider<WindNotifier, WindState>((ref) {
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

class WindNotifier extends StateNotifier<WindState> {
  final WindPipeline _pipeline;
  final List<LocationEntity> Function() _getPoints;
  final int Function() _getCurrentIndex;
  DateTime? _lastTimestamp;

  WindNotifier({
    required this._pipeline,
    required this._getPoints,
    required this._getCurrentIndex,
  })  : super(const WindState());

  void clear() {
    _pipeline.reset();
    _lastTimestamp = null;
    state = const WindState();
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
      
      state = WindState(
        result: latestResult,
        bufferSize: _pipeline.bufferSize,
        bufferAngle: _pipeline.currentBufferAngle,
      );
    } else {
      final result = _pipeline.processLocation(timestamp, speed, heading);
      WindCalculationResult? nextResult = state.result;

      if (result != null) {
        nextResult = result; // Свежие данные (могут быть как валидными, так и забракованными)
      } else {
        if (nextResult != null && nextResult.isValid) {
          nextResult = nextResult.copyWith(isValid: false); // Помечаем как невалидные, если буфер смыт или летим прямо
        }
      }

      // Изменение: Сохраняем и результат (если есть), и живые данные буфера
      state = WindState(
        result: nextResult,
        bufferSize: _pipeline.bufferSize,
        bufferAngle: _pipeline.currentBufferAngle,
      );
    } // конец if-else
  } // конец метода updateLocationWithLogic
} // конец класса WindNotifier
