// Версия: 0.2.0 | Цель: Провайдер ветра

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/location/location_state.dart';
import '../../../core/location/location_entity.dart';
import '../domain/wind_models.dart';
import '../application/wind_pipeline.dart';

final windProvider = StateNotifierProvider<WindNotifier, WindCalculationResult?>((ref) {
  final pipeline = WindPipeline();
  
  final notifier = WindNotifier(
    pipeline: pipeline,
    getPoints: () => ref.read(playbackProvider.notifier).points,
    getCurrentIndex: () => ref.read(playbackProvider).currentIndex,
  );
  
  // Подписываемся на изменения геолокации
  ref.listen(locationProvider, (previous, location) {
    if (location != null) {
      notifier.updateLocation(
        location.timestamp,
        location.speed,
        location.heading,
      );
    }
  });

  return notifier;
});

class WindNotifier extends StateNotifier<WindCalculationResult?> {
  final WindPipeline _pipeline;
  final List<LocationEntity> Function() _getPoints;
  final int Function() _getCurrentIndex;
  DateTime? _lastTimestamp;

  WindNotifier({
    required WindPipeline pipeline,
    required List<LocationEntity> Function() getPoints,
    required int Function() getCurrentIndex,
  })  : _pipeline = pipeline,
        _getPoints = getPoints,
        _getCurrentIndex = getCurrentIndex,
        super(null);

  void updateLocation(DateTime timestamp, double speed, double heading) {
    bool isJump = false;
    if (_lastTimestamp != null) {
      final diff = timestamp.difference(_lastTimestamp!).inMilliseconds;
      // Если время скакнуло назад (diff < 0) или сильно вперед (> 2 секунд)
      if (diff < 0 || diff > 2000) {
        isJump = true;
      }
    }
    _lastTimestamp = timestamp;

    if (isJump) {
      _pipeline.reset();
      
      // Восстанавливаем буфер из истории при перемотке
      final allPoints = _getPoints();
      final currentIndex = _getCurrentIndex();
      
      WindCalculationResult? latestResult;
      if (allPoints.isNotEmpty && currentIndex >= 0 && currentIndex < allPoints.length) {
        final endTime = allPoints[currentIndex].timestamp;
        final startTime = endTime.subtract(Duration(seconds: _pipeline.config.windowSizeSec.toInt()));
        
        // Быстро прогоняем исторические точки через конвейер
        for (int i = 0; i <= currentIndex; i++) {
          final p = allPoints[i];
          if (p.timestamp.isAfter(startTime) || p.timestamp.isAtSameMomentAs(startTime)) {
            // pipeline вернет null или результат, сохраняем последний валидный
            final res = _pipeline.processLocation(p.timestamp, p.speed, p.heading);
            if (res != null) latestResult = res;
          }
        }
      }
      
      state = latestResult; // Обновляем экран сразу вычисленным ветром из истории
    } else {
      final result = _pipeline.processLocation(timestamp, speed, heading);
      
      // Если pipeline вернул новый результат (маневр валиден), обновляем state
      if (result != null) {
        state = result;
      }
    }
  }
}
