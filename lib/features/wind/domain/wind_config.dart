// =============================================================================
// Файл:    wind_config.dart
// Проект:  ParaFlight
// Версия:  1.20.8
// Цель:    Конфигурация модуля ветра
// Изменения:
//   0.2.0 - Первичная реализация
//   1.20.2 - Добавлена максимальная ошибка фиттинга в м/с
//   1.20.8 - Добавлен minBufferPoints, обновлены дефолтные значения (Roundness = 0.5, RMSE = 1.5)
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

  /// Автоматический показ стрелки ветра на радаре
  final bool enableWindArrow;
  
  /// Автоматический показ дебаг окна телеметрии ветра
  final bool enableWindOverlay;

  /// Максимально допустимая ошибка фиттинга в м/с
  final double maxRmseMs;
  
  /// Новое: Минимальное количество точек в буфере
  final int minBufferPoints;

  /// Новое: Коэффициент EMA сглаживания вектора ветра (0.0..1.0)
  final double windEmaAlpha;

  const WindConfig({
    this.windowSizeSec = 120.0,
    this.minTurnAngleDeg = 30.0,
    this.minAirspeedMs = 5.55, // ~20 km/h
    this.maxAirspeedMs = 19.44, // ~70 km/h
    this.sampleIntervalSec = 0.5,
    this.gpxSmoothingWindow = 2,
    this.minCogChangeDeg = 1.0,
    this.minRoundness = 0.5, // Изменение: 0.1 -> 0.5
    this.enableWindArrow = true, 
    this.enableWindOverlay = false,
    this.maxRmseMs = 1.5, // Изменение: 2.0 -> 1.5
    this.minBufferPoints = 20, // Новое
    this.windEmaAlpha = 0.2, // Новое
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
    bool? enableWindArrow,
    bool? enableWindOverlay,
    double? maxRmseMs,
    int? minBufferPoints, // Новое
    double? windEmaAlpha, // Новое
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
      enableWindArrow: enableWindArrow ?? this.enableWindArrow, 
      enableWindOverlay: enableWindOverlay ?? this.enableWindOverlay,
      maxRmseMs: maxRmseMs ?? this.maxRmseMs,
      minBufferPoints: minBufferPoints ?? this.minBufferPoints, // Новое
      windEmaAlpha: windEmaAlpha ?? this.windEmaAlpha, // Новое
    );
  }
}

