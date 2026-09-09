// =============================================================================
// Файл:    vertical_speed_provider.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Провайдер вычисления вертикальной скорости (Vz)
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_entity.dart';
import 'location_state.dart';
import '../../features/settings/application/dashboard_config_provider.dart';

class VerticalSpeedNotifier extends StateNotifier<double> {
  final Ref ref;
  final List<LocationEntity> _buffer = [];

  VerticalSpeedNotifier(this.ref) : super(0.0);

  void addLocation(LocationEntity location) {
    if (_buffer.isNotEmpty) {
      final dt = location.timestamp.difference(_buffer.last.timestamp).inMilliseconds;
      // Если время идет назад или есть сильный пропуск (перемотка), сбрасываем буфер
      if (dt < 0 || dt > 10000) {
        _buffer.clear();
        state = 0.0;
      }
    } // конец if

    _buffer.add(location);

    final config = ref.read(dashboardConfigProvider);
    final cutoff = location.timestamp.subtract(Duration(seconds: config.vzWindowSec));
    _buffer.removeWhere((p) => p.timestamp.isBefore(cutoff));

    if (_buffer.length >= 2) {
      // Линейная регрессия по окну
      double sumX = 0;
      double sumY = 0;
      double sumXY = 0;
      double sumX2 = 0;
      int n = _buffer.length;

      final t0 = _buffer.first.timestamp.millisecondsSinceEpoch;

      for (var p in _buffer) {
        double x = (p.timestamp.millisecondsSinceEpoch - t0) / 1000.0;
        double y = p.altitude;
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
      } // конец for

      double denominator = (n * sumX2 - sumX * sumX);
      if (denominator != 0) {
        double slope = (n * sumXY - sumX * sumY) / denominator;
        state = slope;
      }
    } else {
      state = 0.0;
    } // конец if-else
  } // конец метода addLocation

  void clear() {
    _buffer.clear();
    state = 0.0;
  } // конец метода clear

} // конец класса VerticalSpeedNotifier

final verticalSpeedProvider = StateNotifierProvider<VerticalSpeedNotifier, double>((ref) {
  final notifier = VerticalSpeedNotifier(ref);

  ref.listen(locationProvider, (previous, asyncLocation) {
    final loc = asyncLocation.valueOrNull;
    if (loc != null) {
      notifier.addLocation(loc);
    }
  });

ref.listen(dataSourceProvider, (previous, next) {
    if (previous != next) {
      notifier.clear();
    }
  });

  ref.listen(gpxPointsProvider, (previous, next) {
    notifier.clear();
  });
  
  return notifier;
});
