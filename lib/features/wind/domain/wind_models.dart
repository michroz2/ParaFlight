// Версия: 0.2.0 | Цель: Модели данных для модуля ветра

class WindDataPoint {
  final DateTime timestamp;
  final double vx;
  final double vy;
  final double cog;

  const WindDataPoint({
    required this.timestamp,
    required this.vx,
    required this.vy,
    required this.cog,
  });
}

class WindCalculationResult {
  /// Скорость ветра в м/с
  final double windSpeed;
  
  /// Направление ветра в градусах (метеорологическое: откуда дует, 0-360)
  final double windDirection;
  
  /// Собственная скорость параплана в м/с (радиус окружности)
  final double airspeed;
  
  /// Среднеквадратичная ошибка фиттинга (м/с)
  final double rmse;
  
  final DateTime timestamp;

  const WindCalculationResult({
    required this.windSpeed,
    required this.windDirection,
    required this.airspeed,
    required this.rmse,
    required this.timestamp,
  });
}
