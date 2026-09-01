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
  ref.listen(locationProvider, (previous, asyncLocation) {
    final location = asyncLocation.valueOrNull;
    if (location != null) {
      notifier.updateLocation(
        location.timestamp,
        location.speed,
        location.heading,
        ref.read(dataSourceProvider) == DataSource.simulator,
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
    required List<LocationEntity> Function() getPoints,
    required int Function() getCurrentIndex,
  })  : _getPoints = getPoints,
        _getCurrentIndex = getCurrentIndex,
        super(null);

  void clear() {
    _pipeline.reset();
    _lastTimestamp = null;
    state = null;
  } // конец метода clear

  void updateLocation(DateTime timestamp, double speed, double heading, bool isSimulator) {
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
      
      WindCalculationResult? latestResult;
      
      // Восстанавливаем буфер из истории при перемотке ТОЛЬКО в режиме симулятора
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
            } // конец if
          } // конец for
        } // конец if
      } // конец if
      
      state = latestResult;
    } else {
      final result = _pipeline.processLocation(timestamp, speed, heading);
      if (result != null) {
        state = result;
      }
    } // конец if-else
  } // конец метода updateLocation
} // конец класса WindNotifier
