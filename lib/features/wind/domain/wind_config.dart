// =============================================================================
// Файл:    wind_config.dart
// Проект:  ParaFlight
// Версия:  0.2.0
// Цель:    Конфигурация модуля ветра
// Изменения:
//   0.2.0 - Первичная реализация
// =============================================================================

class WindConfig {
  /// Размер кольцевого буфера в секундах
  final double windowSizeSec;
  
  /// Минимальная разница углов COG для запуска расчета (в градусах)
  final double minTurnAngleDeg;
  
  /// Минимальная воздушная скорость в м/с (15 км/ч)
  final double minAirspeedMs;
  
  /// Максимальная воздушная скорость в м/с (80 км/ч)
  final double maxAirspeedMs;

  /// Минимальный интервал между точками в секундах (для прореживания данных)
  final double sampleIntervalSec;

  /// Размер окна сглаживания GPX (в точках). При 1 сглаживание выключено.
  final int gpxSmoothingWindow;

  /// УГЛОВОЕ ПРОРЕЖИВАНИЕ (Новый метод)
  /// Минимальное изменение курса (в градусах) для добавления точки в буфер.
  /// Защищает буфер от забивания одинаковыми данными на прямой.
  final double minCogChangeDeg;

  /// Минимальная круглость для отсева прямой линии на акселераторе
  final double minRoundness;

  /// Автоматический показ окна ветра
  final bool enableWindOverlay;

  const WindConfig({
    this.windowSizeSec = 120.0,
    this.minTurnAngleDeg = 30.0,
    this.minAirspeedMs = 5.55, // ~20 km/h
    this.maxAirspeedMs = 19.44, // ~70 km/h
    this.sampleIntervalSec = 0.5,
    this.gpxSmoothingWindow = 2,
    this.minCogChangeDeg = 1.0,
    this.minRoundness = 0.1,
    this.enableWindOverlay = false,
  });

  WindConfig copyWith({
    double? windowSizeSec,
    double? minTurnAngleDeg,
    double? minAirspeedMs,
    double? maxAirspeedMs,
    double? sampleIntervalSec,
    int? gpxSmoothingWindow,
    double? minCogChangeDeg,
    double? minRoundness,
    bool? enableWindOverlay,
  }) {
    return WindConfig(
      windowSizeSec: windowSizeSec ?? this.windowSizeSec,
      minTurnAngleDeg: minTurnAngleDeg ?? this.minTurnAngleDeg,
      minAirspeedMs: minAirspeedMs ?? this.minAirspeedMs,
      maxAirspeedMs: maxAirspeedMs ?? this.maxAirspeedMs,
      sampleIntervalSec: sampleIntervalSec ?? this.sampleIntervalSec,
      gpxSmoothingWindow: gpxSmoothingWindow ?? this.gpxSmoothingWindow,
      minCogChangeDeg: minCogChangeDeg ?? this.minCogChangeDeg,
      minRoundness: minRoundness ?? this.minRoundness,
      enableWindOverlay: enableWindOverlay ?? this.enableWindOverlay,
    );
  }
}

