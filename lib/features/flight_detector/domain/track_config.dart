// Версия: 0.1.0 | Цель: Конфигурация детектора полета и трека

class TrackConfig {
  /// Время топтания на месте перед разбегом (в секундах)
  final int takeoffWaitTimeSec;
  
  /// Интервал поддержания полетной скорости для подтверждения старта (в секундах)
  final int takeoffFlightTimeSec;
  
  /// Время нулевой скорости для подтверждения посадки (в секундах)
  final int landingConfirmTimeSec;
  
  /// Порог полетной скорости в м/с (по умолчанию ~15 км/ч)
  final double minFlightSpeedMs;
  
  /// Порог скорости ходьбы в м/с (по умолчанию ~5 км/ч)
  final double maxWalkSpeedMs;

  /// Минимальная SOG для активации ветра и Mid-Air старта (м/с)
  final double cfvMinFlightSog;

  /// Минимальная SOG для фильтра поворота на перекрестке (м/с)
  final double cfvTurnMinSog;

  /// Порог SOG для детекта трассы/автомобиля (м/с)
  final double cfvHighwaySog;

  /// Таймаут падения ветра перед дисквалификацией полета (сек)
  final int cfvWindFailTimeoutSec;

  const TrackConfig({
    this.takeoffWaitTimeSec = 5,
    this.takeoffFlightTimeSec = 15,
    this.landingConfirmTimeSec = 10,
    this.minFlightSpeedMs = 4.16, // ~15 km/h
    this.maxWalkSpeedMs = 1.38,   // ~5 km/h
    this.cfvMinFlightSog = 2.77,  // ~10 km/h
    this.cfvTurnMinSog = 5.55,    // ~20 km/h
    this.cfvHighwaySog = 25.0,    // ~90 km/h
    this.cfvWindFailTimeoutSec = 60,
  });

  TrackConfig copyWith({
    int? takeoffWaitTimeSec,
    int? takeoffFlightTimeSec,
    int? landingConfirmTimeSec,
    double? minFlightSpeedMs,
    double? maxWalkSpeedMs,
    double? cfvMinFlightSog,
    double? cfvTurnMinSog,
    double? cfvHighwaySog,
    int? cfvWindFailTimeoutSec,
  }) {
    return TrackConfig(
      takeoffWaitTimeSec: takeoffWaitTimeSec ?? this.takeoffWaitTimeSec,
      takeoffFlightTimeSec: takeoffFlightTimeSec ?? this.takeoffFlightTimeSec,
      landingConfirmTimeSec: landingConfirmTimeSec ?? this.landingConfirmTimeSec,
      minFlightSpeedMs: minFlightSpeedMs ?? this.minFlightSpeedMs,
      maxWalkSpeedMs: maxWalkSpeedMs ?? this.maxWalkSpeedMs,
      cfvMinFlightSog: cfvMinFlightSog ?? this.cfvMinFlightSog,
      cfvTurnMinSog: cfvTurnMinSog ?? this.cfvTurnMinSog,
      cfvHighwaySog: cfvHighwaySog ?? this.cfvHighwaySog,
      cfvWindFailTimeoutSec: cfvWindFailTimeoutSec ?? this.cfvWindFailTimeoutSec,
    );
  }
} // конец класса TrackConfig
