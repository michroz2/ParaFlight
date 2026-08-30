import 'location_entity.dart';
import 'location_provider.dart';

/// Провайдер, симулирующий движение на основе заранее заданного списка точек.
/// Воспроизводит точные тайминги между точками.
class SimulatorLocationProvider implements LocationProvider {
  /// Список точек маршрута для симуляции
  final List<LocationEntity> points;

  /// Инициализация симулятора заданным набором точек
  SimulatorLocationProvider(this.points);

  @override
  Stream<LocationEntity> get locationStream async* {
    if (points.isEmpty) return;

    // Выдаем первую точку сразу
    yield points.first;

    // Воспроизводим последующие точки с учетом реальных задержек времени
    for (int i = 1; i < points.length; i++) {
      final previousPoint = points[i - 1];
      final currentPoint = points[i];
      
      // Вычисляем разницу во времени между текущей и предыдущей точкой
      final difference = currentPoint.timestamp.difference(previousPoint.timestamp);
      
      // Ждем необходимое время
      if (difference > Duration.zero) {
        await Future.delayed(difference);
      }
      
      yield currentPoint;
    }
  }
}
