// =============================================================================
// Файл:    wind_models.dart
// Проект:  ParaFlight
// Версия:  1.20.2
// Цель:    Модели данных для модуля ветра
// Изменения:
//   0.2.0 - Первичная реализация
//   1.20.2 - Добавлен флаг устаревших данных (когда буфер промывается от яда)
// =============================================================================

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
  
  /// Безразмерный параметр округлости (0..1)
  final double roundness;
  
  final DateTime timestamp;

  // Новое: Флаг устаревших данных (когда буфер промывается от яда)
  final bool isStale;

  const WindCalculationResult({
    required this.windSpeed,
    required this.windDirection,
    required this.airspeed,
    required this.rmse,
    required this.roundness,
    required this.timestamp,
    this.isStale = false, 
  });
  // Новое: Метод copyWith для безопасного обновления состояния
  WindCalculationResult copyWith({
    double? windSpeed,
    double? windDirection,
    double? airspeed,
    double? rmse,
    double? roundness,
    DateTime? timestamp,
    bool? isStale,
  }) {
    return WindCalculationResult(
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      airspeed: airspeed ?? this.airspeed,
      rmse: rmse ?? this.rmse,
      roundness: roundness ?? this.roundness,
      timestamp: timestamp ?? this.timestamp,
      isStale: isStale ?? this.isStale,
    );
  }
}