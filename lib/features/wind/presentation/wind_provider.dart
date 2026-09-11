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
import 'dart:math' as math;
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
  double? _smoothedWx;
  double? _smoothedWy;

  WindNotifier({
    required WindPipeline pipeline,
  })  : _pipeline = pipeline,
        super(const WindState());

  void clear() {
    _pipeline.reset();
    _smoothedWx = null;
    _smoothedWy = null;
    state = const WindState();
  } // конец метода clear

  // Новое: Инкапсулированный метод для централизованного сброса
  void forceReset() {
    _pipeline.reset();
    _smoothedWx = null;
    _smoothedWy = null;
    
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
        // 1. Конвертируем полярные координаты в декартовы
        // (Угол в радианах, Север = 0)
        final double dirRad = latestResult.windDirection * (math.pi / 180.0);
        final double rawWx = latestResult.windSpeed * math.sin(dirRad);
        final double rawWy = latestResult.windSpeed * math.cos(dirRad);

        // 2. Применяем EMA-фильтр
        if (state.mapResult == null || !state.mapResult!.isValid || _smoothedWx == null || _smoothedWy == null) {
          // Если предыдущий ветер был невалидным, сбрасываем фильтр (моментальный щелчок)
          _smoothedWx = rawWx;
          _smoothedWy = rawWy;
        } else {
          // Плавно сглаживаем новые значения
          final alpha = _pipeline.config.windEmaAlpha;
          _smoothedWx = alpha * rawWx + (1.0 - alpha) * _smoothedWx!;
          _smoothedWy = alpha * rawWy + (1.0 - alpha) * _smoothedWy!;
        }

        // 3. Конвертируем обратно в полярные координаты
        final double smoothedSpeed = math.sqrt(_smoothedWx! * _smoothedWx! + _smoothedWy! * _smoothedWy!);
        // Функция atan2(x, y) для отсчета угла от оси Y (Север) по часовой стрелке
        double smoothedDir = math.atan2(_smoothedWx!, _smoothedWy!) * (180.0 / math.pi);
        if (smoothedDir < 0) smoothedDir += 360.0;

        // 4. Обновляем карту сглаженными значениями (остальные параметры типа RMSE берем из сырого)
        newMap = latestResult.copyWith(
          windSpeed: smoothedSpeed,
          windDirection: smoothedDir,
        );
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
