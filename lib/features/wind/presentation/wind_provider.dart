// =============================================================================
// Файл:    wind_provider.dart
// Проект:  ParaFlight
// Версия:  1.20.7
// Цель:    Провайдер ветра
// Изменения:
//   0.2.0 - Первичная реализация
//   1.20.2 - Улучшен расчет амбиентного ветра. Собирается Минимальный рабочий буфер. Если расчеты дают некорректные ошибки, буфер очищается.
//   1.20.4 - Замена состояния на WindState
//   1.20.5 - Замена isStale на isValid
//   1.20.7 - Устранение костылей для перемотки. Переход на единый сигнал seekCount (DRY)
// =============================================================================

// ignore_for_file: prefer_initializing_formals

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/location/location_state.dart';
import '../domain/wind_models.dart';
import '../application/wind_pipeline.dart'; // Восстановленный импорт

import '../../settings/application/wind_config_provider.dart';

final StateNotifierProvider<WindNotifier, WindState> windProvider = StateNotifierProvider<WindNotifier, WindState>((ref) {
  final config = ref.watch(windConfigProvider);
  final pipeline = WindPipeline(config: config);
  
  final notifier = WindNotifier(
    pipeline: pipeline,
  );
  
  // Подписываемся на изменения геолокации
  ref.listen(locationProvider, (previous, asyncLocation) {
    final location = asyncLocation.valueOrNull;
    
    if (location != null) {
      notifier.updateLocationWithLogic(
        timestamp: location.timestamp,
        speed: location.speed,
        heading: location.heading,
      );
    }
  });

  // Подписываемся на смену источника данных
  ref.listen(dataSourceProvider, (previous, next) {
    if (previous != next) {
      notifier.clear();
    } // конец if
  });

  // Новое: Слушаем централизованный сигнал перемотки (DRY)
  ref.listen(playbackProvider.select((s) => s.seekCount), (previous, current) {
    if (previous != null && current != previous) {
      notifier.forceReset();
    }
  });

  return notifier;
});

class WindNotifier extends StateNotifier<WindState> {
  final WindPipeline _pipeline;

  WindNotifier({
    required WindPipeline pipeline,
  })  : _pipeline = pipeline,
        super(const WindState());

  void clear() {
    _pipeline.reset();
    state = const WindState();
  } // конец метода clear

  // Новое: Инкапсулированный метод для централизованного сброса
  void forceReset() {
    _pipeline.reset();
    
    // Защита телеметрии: оставляем цифры, но делаем их серыми
    if (state.telemetryResult != null || state.mapResult != null) {
      state = WindState(
        mapResult: state.mapResult?.copyWith(isValid: false),
        telemetryResult: state.telemetryResult?.copyWith(isValid: false),
        bufferSize: 0,
        bufferAngle: 0.0,
      );
    } else {
      state = const WindState();
    }
  } // конец метода forceReset

  void updateLocationWithLogic({
    required DateTime timestamp,
    required double speed,
    required double heading,
  }) {
    // Делегируем в конвейер (вся логика определения скачков удалена - Separation of Concerns)
    final latestResult = _pipeline.processLocation(timestamp, speed, heading);
    
    WindCalculationResult? newTelemetry = state.telemetryResult;
    WindCalculationResult? newMap = state.mapResult;

    if (latestResult != null) {
      // Телеметрия получает всё (чтобы подсветить ошибки красным)
      newTelemetry = latestResult; 
      
      if (latestResult.isValid) {
        // Расчет идеален - обновляем стрелку компаса
        newMap = latestResult; 
      } else {
        // ВАЛИДАТОР ЗАБРАКОВАЛ РАСЧЕТ:
        // Компас сохраняет старое направление, но стрелка мгновенно становится серой
        newMap = state.mapResult?.copyWith(isValid: false);
      }
    } 
    // Если latestResult == null (полет по прямой, нет маневра) - ничего не меняем, старые данные живут.

    state = WindState(
      mapResult: newMap,
      telemetryResult: newTelemetry,
      bufferSize: _pipeline.bufferSize,
      bufferAngle: _pipeline.currentBufferAngle,
    );
  } // конец метода updateLocationWithLogic
} // конец класса WindNotifier
