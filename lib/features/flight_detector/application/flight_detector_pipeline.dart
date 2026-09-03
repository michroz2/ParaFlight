// Версия: 0.1.0 | Цель: Логика детектора полета (State Machine и Паттерны)

import '../../../core/location/location_entity.dart';
import '../domain/flight_state.dart';
import '../domain/track_config.dart';
import '../../wind/domain/wind_models.dart';

class FlightDetectorPipeline {
  final TrackConfig config;
  final void Function(String message)? onLog;
  final List<LocationEntity> _buffer = [];

  FlightState _currentState = FlightState.groundMovement;
  
  final List<FlightRecord> _flights = [];

  FlightDetectorPipeline({
    this.config = const TrackConfig(),
    this.onLog,
  });

  FlightState get currentState => _currentState;
  List<FlightRecord> get flights => _flights;
  LocationEntity? get startMark => _flights.isNotEmpty ? _flights.last.start : null;
  LocationEntity? get finishMark => _flights.isNotEmpty ? _flights.last.finish : null;
  List<LocationEntity> get buffer => _buffer;

  void reset() {
    _buffer.clear();
    _flights.clear();
    _currentState = FlightState.groundMovement;
  } // конец метода reset

  DateTime? _lastValidWindTime;
  DateTime? _highwayStartTime;

  void processLocation(LocationEntity point, {WindCalculationResult? currentWind}) {
    _buffer.add(point);
    
    // Поддерживаем буфер размером 60 секунд
    final cutoffTime = point.timestamp.subtract(const Duration(seconds: 60));
    _buffer.removeWhere((p) => p.timestamp.isBefore(cutoffTime));

    if (_currentState == FlightState.groundMovement || _currentState == FlightState.landing) {
      if (_currentState == FlightState.landing) {
         _currentState = FlightState.groundMovement;
      }
      _checkTakeoffPattern();
      if (_currentState == FlightState.groundMovement) {
        _checkMidAirStartPattern(point);
      }
    } else if (_currentState == FlightState.inFlight) {
      _checkCfvDisqualification(point, currentWind);
      if (_currentState == FlightState.inFlight) {
        _checkLandingPattern();
      }
    } // конец if-else
  } // конец метода processLocation

  void _checkMidAirStartPattern(LocationEntity point) {
    if (_buffer.isEmpty) return;

    final now = point.timestamp;
    final windowStart = now.subtract(const Duration(seconds: 15));
    
    final recentPoints = _buffer.where((p) => p.timestamp.isAfter(windowStart) || p.timestamp.isAtSameMomentAs(windowStart)).toList();
    
    // Убедимся, что у нас есть данные хотя бы за 10 секунд
    if (recentPoints.isNotEmpty && now.difference(recentPoints.first.timestamp).inSeconds >= 10) {
      // Презумпция полета: если скорость стабильно выше полетной, считаем что летим
      bool isHighSpeed = recentPoints.every((p) => p.speed >= config.minFlightSpeedMs);
      
      if (isHighSpeed) {
        final start = recentPoints.first;
        _flights.add(FlightRecord(start: start, isMidAirStart: true));
        _currentState = FlightState.inFlight;
        _lastValidWindTime = now;
        _highwayStartTime = null;
        onLog?.call("Status changed: GroundMovement -> InFlight (MidAir)");
      }
    }
  } // конец метода _checkMidAirStartPattern

  void _checkCfvDisqualification(LocationEntity point, WindCalculationResult? currentWind) {
    bool disqualify = false;
    final now = point.timestamp;

    // 1. Провал по ветру
    if (currentWind != null && currentWind.airspeed >= 6.94 && currentWind.airspeed <= 18.0) { // 25-65 км/ч
      _lastValidWindTime = now;
    } else {
      if (_lastValidWindTime != null) {
        if (now.difference(_lastValidWindTime!).inSeconds > config.cfvWindFailTimeoutSec) {
          disqualify = true;
          onLog?.call("CFV KILLED: Wind Fail Timeout (No valid wind for 60s)");
        }
      } else {
        _lastValidWindTime = now;
      }
    }

    // 2. Правило трассы
    if (point.speed > config.cfvHighwaySog) {
      _highwayStartTime ??= now;
      if (now.difference(_highwayStartTime!).inSeconds > 30) {
        disqualify = true;
        onLog?.call("CFV KILLED: Highway Rule. SOG > 90");
      }
    } else {
      _highwayStartTime = null;
    }

    // 3. Фильтр перекрестка
    if (_buffer.length >= 5) {
      final turnWindowStart = now.subtract(const Duration(seconds: 5));
      final turnPoints = _buffer.where((p) => p.timestamp.isAfter(turnWindowStart) || p.timestamp.isAtSameMomentAs(turnWindowStart)).toList();
      if (turnPoints.isNotEmpty) {
        final minSog = turnPoints.map((p) => p.speed).reduce((a, b) => a < b ? a : b);
        if (minSog < config.cfvTurnMinSog) {
          double maxDelta = 0;
          for (int i = 0; i < turnPoints.length; i++) {
            for (int j = i + 1; j < turnPoints.length; j++) {
              double delta = (turnPoints[i].heading - turnPoints[j].heading).abs();
              if (delta > 180.0) delta = 360.0 - delta;
              if (delta > maxDelta) maxDelta = delta;
            }
          }
          if (maxDelta > 50.0) {
            disqualify = true;
            onLog?.call("CFV KILLED: Intersection! DeltaCOG: ${maxDelta.toStringAsFixed(1)}, SOG: ${(minSog * 3.6).toStringAsFixed(1)} km/h");
          }
        }
      }
    }

    if (disqualify) {
      if (_flights.isNotEmpty && _flights.last.finish == null) {
        _flights.removeLast();
      }
      _currentState = FlightState.groundMovement;
      _lastValidWindTime = null;
      _highwayStartTime = null;
    }
  } // конец метода _checkCfvDisqualification

  void _checkTakeoffPattern() {
    if (_buffer.isEmpty) return;
    
    final now = _buffer.last.timestamp;
    final flightWindowStart = now.subtract(Duration(seconds: config.takeoffFlightTimeSec));
    
    final flightPoints = _buffer.where((p) => p.timestamp.isAfter(flightWindowStart) || p.timestamp.isAtSameMomentAs(flightWindowStart)).toList();
    
    if (flightPoints.isEmpty) return;

    // Проверяем среднюю скорость в полетном окне
    final avgFlightSpeed = flightPoints.map((p) => p.speed).reduce((a, b) => a + b) / flightPoints.length;
    if (avgFlightSpeed < config.minFlightSpeedMs) return;

    // Ищем точку P1 (начало разбега), двигаясь назад от flightWindowStart
    final beforeFlightPoints = _buffer.where((p) => p.timestamp.isBefore(flightWindowStart)).toList();
    if (beforeFlightPoints.isEmpty) return;

    // Ищем ближайшую к flightWindowStart точку, где скорость была <= maxWalkSpeedMs
    LocationEntity? p1;
    for (int i = beforeFlightPoints.length - 1; i >= 0; i--) {
      if (beforeFlightPoints[i].speed <= config.maxWalkSpeedMs) {
        p1 = beforeFlightPoints[i];
        break;
      }
    } // конец for

    if (p1 == null) return;

    // Проверяем "топтание на месте" до P1
    final waitWindowStart = p1.timestamp.subtract(Duration(seconds: config.takeoffWaitTimeSec));
    final waitPoints = _buffer.where((p) => 
      (p.timestamp.isAfter(waitWindowStart) || p.timestamp.isAtSameMomentAs(waitWindowStart)) && 
      (p.timestamp.isBefore(p1!.timestamp) || p.timestamp.isAtSameMomentAs(p1.timestamp))
    ).toList();

    if (waitPoints.isEmpty) return;

    // В окне топтания средняя скорость должна быть низкой
    final avgWaitSpeed = waitPoints.map((p) => p.speed).reduce((a, b) => a + b) / waitPoints.length;
    if (avgWaitSpeed > config.maxWalkSpeedMs) return;

    // Проверяем рост высоты: текущая высота должна быть больше средней высоты топтания
    final avgWaitAltitude = waitPoints.map((p) => p.altitude).reduce((a, b) => a + b) / waitPoints.length;
    if (_buffer.last.altitude <= avgWaitAltitude) return;

    // Паттерн совпал!
    _flights.add(FlightRecord(start: p1));
    _currentState = FlightState.inFlight;
    onLog?.call("Status changed: GroundMovement -> InFlight");
  } // конец метода _checkTakeoffPattern

  void _checkLandingPattern() {
    if (_buffer.isEmpty) return;
    
    final now = _buffer.last.timestamp;
    final confirmWindowStart = now.subtract(Duration(seconds: config.landingConfirmTimeSec));
    
    final confirmPoints = _buffer.where((p) => p.timestamp.isAfter(confirmWindowStart) || p.timestamp.isAtSameMomentAs(confirmWindowStart)).toList();
    
    if (confirmPoints.isEmpty) return;

    // В окне подтверждения скорость должна быть нулевой (<= maxWalkSpeedMs)
    bool isStopped = confirmPoints.every((p) => p.speed <= config.maxWalkSpeedMs);
    if (!isStopped) return;

    // Проверяем Vz (отсутствие болтанки по высоте). Амплитуда высоты должна быть небольшой
    final minAlt = confirmPoints.map((p) => p.altitude).reduce((a, b) => a < b ? a : b);
    final maxAlt = confirmPoints.map((p) => p.altitude).reduce((a, b) => a > b ? a : b);
    if ((maxAlt - minAlt) > 3.0) return; // Болтанка более 3 метров

    // Ищем точку касания P2 (первая точка с нулевой скоростью перед confirmWindowStart)
    final beforeConfirmPoints = _buffer.where((p) => p.timestamp.isBefore(confirmWindowStart)).toList();
    if (beforeConfirmPoints.isEmpty) return;

    LocationEntity? p2;
    // Идем с конца (от confirmWindowStart) назад, пока скорость нулевая. Как только выросла - предыдущая была P2
    p2 = confirmPoints.first; // По умолчанию P2 - начало окна подтверждения
    for (int i = beforeConfirmPoints.length - 1; i >= 0; i--) {
      if (beforeConfirmPoints[i].speed <= config.maxWalkSpeedMs) {
        p2 = beforeConfirmPoints[i];
      } else {
        break; // Скорость начала расти, значит нашли первую точку остановки
      }
    } // конец for

    if (p2 == null) return;

    // Проверяем глиссаду (снижение) перед P2
    final glideWindowStart = p2.timestamp.subtract(const Duration(seconds: 5));
    final glidePoints = _buffer.where((p) => 
      p.timestamp.isAfter(glideWindowStart) && p.timestamp.isBefore(p2!.timestamp)
    ).toList();

    if (glidePoints.isNotEmpty) {
      final startGlideAlt = glidePoints.first.altitude;
      final endGlideAlt = p2.altitude;
      // Если высота не падала, это может быть не посадка (но оставляем мягкое условие)
      if (endGlideAlt > startGlideAlt + 1.0) return; // Если высота сильно выросла - ложная тревога
    } // конец if

    // Паттерн совпал!
    if (_flights.isNotEmpty) {
      _flights.last.finish = p2;
    }
    _currentState = FlightState.landing;
    onLog?.call("Status changed to Landing");
  } // конец метода _checkLandingPattern
} // конец класса FlightDetectorPipeline
