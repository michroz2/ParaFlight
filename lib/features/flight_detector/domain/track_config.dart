// Версия: 0.1.0 | Цель: Конфигурация детектора полета и трека

class TrackConfig {
  /// Автоматика
  final bool enableAutoTakeoff;
  final bool enableMidAirStart;
  final bool enableAutoLanding;
  final bool enableCfvWindFail;
  final bool enableCfvIntersection;
  final bool enableCfvHighway;
  final bool enableDebugMarkers;

  /// Время в секундах, в течение которого пилот должен "топтаться" перед разбегом (ожидание)
  final int takeoffWaitTimeSec;

  /// Время в секундах стабильного движения, необходимое для подтверждения взлета
  final int takeoffFlightTimeSec;

  /// Время в секундах для подтверждения факта посадки (полная остановка)
  final int landingConfirmTimeSec;

  /// Минимальная полетная скорость в м/с (для старта и фильтров)
  final double minFlightSpeedMs;

  /// Максимальная скорость движения пешком в м/с (используется для поиска точки начала разбега)
  final double maxWalkSpeedMs;

  /// CFV: Минимальная скорость SOG в полете (м/с) - ниже которой считается, что аппарат на земле, если он не параплан.
  final double cfvMinFlightSog;

  /// CFV: Минимальная скорость, при которой работает проверка поворотов (м/с)
  final double cfvTurnMinSog;

  /// CFV: Максимальная полетная скорость (м/с) (отсев езды по трассе)
  final double cfvHighwaySog;

  /// Таймаут падения ветра перед дисквалификацией полета (сек)
  final int cfvWindFailTimeoutSec;

  /// Окно поворота на перекрестке (сек)
  final int cfvTurnWindowSec;

  /// Интервал записи GPX (сек)
  final double gpsRecordIntervalSec;

  /// Настройка обрезки лишнего трека после посадки
  final int gpsCleanupExtraSec;

  const TrackConfig({
    this.enableAutoTakeoff = true,
    this.enableMidAirStart = true,
    this.enableAutoLanding = true,
    this.enableCfvWindFail = false,
    this.enableCfvIntersection = false,
    this.enableCfvHighway = false,
    this.enableDebugMarkers = false,
    this.takeoffWaitTimeSec = 5,
    this.takeoffFlightTimeSec = 15,
    this.landingConfirmTimeSec = 10,
    this.minFlightSpeedMs = 4.16, // ~15 km/h
    this.maxWalkSpeedMs = 1.38, // ~5 km/h
    this.cfvMinFlightSog = 2.77, // ~10 km/h
    this.cfvTurnMinSog = 5.55, // ~20 km/h
    this.cfvHighwaySog = 25.0, // ~90 km/h
    this.cfvWindFailTimeoutSec = 180,
    this.cfvTurnWindowSec = 5,
    this.gpsRecordIntervalSec = 0.5,
    this.gpsCleanupExtraSec = 30,
  });

  TrackConfig copyWith({
    bool? enableAutoTakeoff,
    bool? enableMidAirStart,
    bool? enableAutoLanding,
    bool? enableCfvWindFail,
    bool? enableCfvIntersection,
    bool? enableCfvHighway,
    bool? enableDebugMarkers,
    int? takeoffWaitTimeSec,
    int? takeoffFlightTimeSec,
    int? landingConfirmTimeSec,
    double? minFlightSpeedMs,
    double? maxWalkSpeedMs,
    double? cfvMinFlightSog,
    double? cfvTurnMinSog,
    double? cfvHighwaySog,
    int? cfvWindFailTimeoutSec,
    int? cfvTurnWindowSec,
    double? gpsRecordIntervalSec,
    int? gpsCleanupExtraSec,
  }) {
    return TrackConfig(
      enableAutoTakeoff: enableAutoTakeoff ?? this.enableAutoTakeoff,
      enableMidAirStart: enableMidAirStart ?? this.enableMidAirStart,
      enableAutoLanding: enableAutoLanding ?? this.enableAutoLanding,
      enableCfvWindFail: enableCfvWindFail ?? this.enableCfvWindFail,
      enableCfvIntersection: enableCfvIntersection ?? this.enableCfvIntersection,
      enableCfvHighway: enableCfvHighway ?? this.enableCfvHighway,
      enableDebugMarkers: enableDebugMarkers ?? this.enableDebugMarkers,
      takeoffWaitTimeSec: takeoffWaitTimeSec ?? this.takeoffWaitTimeSec,
      takeoffFlightTimeSec: takeoffFlightTimeSec ?? this.takeoffFlightTimeSec,
      landingConfirmTimeSec:
          landingConfirmTimeSec ?? this.landingConfirmTimeSec,
      minFlightSpeedMs: minFlightSpeedMs ?? this.minFlightSpeedMs,
      maxWalkSpeedMs: maxWalkSpeedMs ?? this.maxWalkSpeedMs,
      cfvMinFlightSog: cfvMinFlightSog ?? this.cfvMinFlightSog,
      cfvTurnMinSog: cfvTurnMinSog ?? this.cfvTurnMinSog,
      cfvHighwaySog: cfvHighwaySog ?? this.cfvHighwaySog,
      cfvWindFailTimeoutSec:
          cfvWindFailTimeoutSec ?? this.cfvWindFailTimeoutSec,
      cfvTurnWindowSec: cfvTurnWindowSec ?? this.cfvTurnWindowSec,
      gpsRecordIntervalSec: gpsRecordIntervalSec ?? this.gpsRecordIntervalSec,
      gpsCleanupExtraSec: gpsCleanupExtraSec ?? this.gpsCleanupExtraSec,
    );
  }
} // конец класса TrackConfig
