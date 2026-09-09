// =============================================================================
// Файл:    flight_detector_pipeline.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Логика детектора полета (State Machine и Паттерны)
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================

import '../../../core/location/location_entity.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import '../domain/flight_state.dart';
import '../domain/track_config.dart';
import '../../wind/domain/wind_models.dart';

class FlightDetectorPipeline {
  final TrackConfig config;
  final void Function(DateTime time, double lat, double lon, String reason)? onLogEvent;
  final List<LocationEntity> _buffer = [];

  FlightState _currentState = FlightState.groundMovement;
  
  final List<FlightRecord> _flights = [];
  
  double _totalTrackDistance = 0.0;
  Duration _totalTrackDuration = Duration.zero;
  LocationEntity? _lastLocation;

  FlightDetectorPipeline({
    this.config = const TrackConfig(),
    this.onLogEvent,
  });

  FlightState get currentState => _currentState;
  List<FlightRecord> get flights => _flights;
  LocationEntity? get startMark => _flights.isNotEmpty ? _flights.last.start : null;
  LocationEntity? get finishMark => _flights.isNotEmpty ? _flights.last.finish : null;
  List<LocationEntity> get buffer => _buffer;
  
  double get currentDistance {
    if (_flights.isEmpty) return _totalTrackDistance;
    return _flights.fold(0.0, (sum, f) => sum + f.distance);
  }
  
  Duration get currentDuration {
    if (_flights.isEmpty) return _totalTrackDuration;
    return _flights.fold(Duration.zero, (sum, f) => sum + f.duration);
  }

  void reset() {
    _buffer.clear();
    _flights.clear();
    _currentState = FlightState.groundMovement;
    _totalTrackDistance = 0.0;
    _totalTrackDuration = Duration.zero;
    _lastLocation = null;
  } // конец метода reset

  DateTime? _lastValidWindTime;
  DateTime? _highwayStartTime;

  void processLocation(LocationEntity point, {WindCalculationResult? currentWind, bool useCalculatedSpeed = false}) {
    double deltaDist = 0.0;
    Duration deltaT = Duration.zero;
    
    // Используем аппаратную скорость по умолчанию.
    // Вычисляем математическую, если это запрошено (useCalculatedSpeed) или если мы в режиме симулятора
    double calcSpeed = point.speed;
    double calcHeading = point.heading;
    
    if (_lastLocation != null) {
      final distance = const latlong2.Distance();
      deltaDist = distance.as(latlong2.LengthUnit.Meter, latlong2.LatLng(_lastLocation!.latitude, _lastLocation!.longitude), latlong2.LatLng(point.latitude, point.longitude));
      deltaT = point.timestamp.difference(_lastLocation!.timestamp);
    }

    if (useCalculatedSpeed && _buffer.isNotEmpty) {
      // Ищем точку примерно 4 секунды назад для сглаживания (а не 4 индекса, так как при даунсэмплинге 4 индекса могут быть 20 секундами!)
      final targetTime = point.timestamp.subtract(const Duration(seconds: 4));
      LocationEntity prev = _buffer.last;
      for (int i = _buffer.length - 1; i >= 0; i--) {
        prev = _buffer[i];
        if (prev.timestamp.isBefore(targetTime) || prev.timestamp.isAtSameMomentAs(targetTime)) {
          break; // Нашли точку >= 4 секунд назад
        }
      }

      final dist = const latlong2.Distance().as(latlong2.LengthUnit.Meter, latlong2.LatLng(prev.latitude, prev.longitude), latlong2.LatLng(point.latitude, point.longitude));
      final ms = point.timestamp.difference(prev.timestamp).inMilliseconds;
      if (ms > 0) {
        calcSpeed = (dist / ms) * 1000.0;
        calcHeading = const latlong2.Distance().bearing(latlong2.LatLng(prev.latitude, prev.longitude), latlong2.LatLng(point.latitude, point.longitude));
        if (calcHeading < 0) calcHeading += 360.0;
      }
    }

    final p = LocationEntity(
      latitude: point.latitude,
      longitude: point.longitude,
      altitude: point.altitude,
      speed: calcSpeed,
      heading: calcHeading,
      timestamp: point.timestamp,
    );
    
    _totalTrackDistance += deltaDist;
    _totalTrackDuration += deltaT;
    
    _buffer.add(p);
    
    if (_currentState == FlightState.inFlight && _flights.isNotEmpty) {
      _flights.last.distance += deltaDist;
      _flights.last.duration += deltaT;
    }
    
    // Поддерживаем буфер размером 60 секунд
    final cutoffTime = point.timestamp.subtract(const Duration(seconds: 60));
    _buffer.removeWhere((p) => p.timestamp.isBefore(cutoffTime));

    if (_currentState == FlightState.groundMovement || _currentState == FlightState.landing) {
      if (_currentState == FlightState.landing) {
         _currentState = FlightState.groundMovement;
    _totalTrackDistance = 0.0;
    _totalTrackDuration = Duration.zero;
    _lastLocation = null;
      }
      if (config.enableAutoTakeoff) {
        _checkTakeoffPattern();
      }
      if (_currentState == FlightState.groundMovement && config.enableMidAirStart) {
        _checkMidAirStartPattern(point);
      }
    } else if (_currentState == FlightState.inFlight) {
      _checkCfvDisqualification(point, currentWind);
      if (_currentState == FlightState.inFlight && config.enableAutoLanding) {
        _checkLandingPattern();
      }
    } // конец if-else
    _lastLocation = p;
  } // конец метода processLocation

  void _checkMidAirStartPattern(LocationEntity point) {
    if (_currentState == FlightState.inFlight) return;
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
        
        double retroactiveDist = 0.0;
        Duration retroactiveTime = Duration.zero;
        bool foundStart = false;
        LocationEntity? prev;
        for (var p in _buffer) {
          if (p == start) foundStart = true;
          if (foundStart) {
            if (prev != null) {
              retroactiveDist += const latlong2.Distance().as(latlong2.LengthUnit.Meter, latlong2.LatLng(prev.latitude, prev.longitude), latlong2.LatLng(p.latitude, p.longitude));
              retroactiveTime += p.timestamp.difference(prev.timestamp);
            }
            prev = p;
          }
        }
        
        _flights.add(FlightRecord(start: start, isMidAirStart: true, distance: retroactiveDist, duration: retroactiveTime));
        _currentState = FlightState.inFlight;
        _lastValidWindTime = now;
        _highwayStartTime = null;
        onLogEvent?.call(point.timestamp, point.latitude, point.longitude, "Паттерн: Mid-Air Start");
      }
    }
  } // конец метода _checkMidAirStartPattern

  void _checkCfvDisqualification(LocationEntity point, WindCalculationResult? currentWind) {
    bool disqualify = false;
    final now = point.timestamp;

    // 1. Провал по ветру
    if (config.enableCfvWindFail) {
      if (currentWind != null && currentWind.airspeed >= 6.94 && currentWind.airspeed <= 18.0) { // 25-65 км/ч
        _lastValidWindTime = now;
      } else {
        if (_lastValidWindTime != null) {
          if (now.difference(_lastValidWindTime!).inSeconds > config.cfvWindFailTimeoutSec) {
            disqualify = true;
            onLogEvent?.call(point.timestamp, point.latitude, point.longitude, "Провал ветра: нет валидных данных > ${config.cfvWindFailTimeoutSec} сек");
          }
        } else {
          _lastValidWindTime = now;
        }
      }
    }

    // 2. Правило трассы
    if (config.enableCfvHighway && !disqualify) {
      if (point.speed > config.cfvHighwaySog) {
        _highwayStartTime ??= now;
        if (now.difference(_highwayStartTime!).inSeconds > 30) {
          disqualify = true;
          onLogEvent?.call(point.timestamp, point.latitude, point.longitude, "Трасса: SOG > 90");
        }
      } else {
        _highwayStartTime = null;
      }
    }

    // 3. Фильтр перекрестка
    if (config.enableCfvIntersection && !disqualify) {
      if (point.speed < config.cfvTurnMinSog) {
        final windowStart = now.subtract(Duration(seconds: config.cfvTurnWindowSec));
        final turnPoints = _buffer.where((p) => p.timestamp.isAfter(windowStart)).toList();
        
        if (turnPoints.isNotEmpty) {
          double minSog = turnPoints.map((p) => p.speed).reduce((a, b) => a < b ? a : b);
          if (minSog < config.cfvTurnMinSog) {
            double maxDelta = 0.0;
            for (int i = 1; i < turnPoints.length; i++) {
              double delta = (turnPoints[i].heading - turnPoints[i - 1].heading).abs();
              if (delta > 180.0) delta = 360.0 - delta;
              if (delta > maxDelta) maxDelta = delta;
            }
            if (maxDelta > 50.0) {
              disqualify = true;
              onLogEvent?.call(point.timestamp, point.latitude, point.longitude, "Перекресток: dCOG=${maxDelta.toStringAsFixed(1)}, SOG=${(minSog * 3.6).toStringAsFixed(1)}");
            }
          }
        }
      }
    }

    if (disqualify) {
      if (_flights.isNotEmpty && _flights.last.finish == null) {
        _flights.removeLast();
      }
      _currentState = FlightState.groundMovement;
    _totalTrackDistance = 0.0;
    _totalTrackDuration = Duration.zero;
    _lastLocation = null;
      _lastValidWindTime = null;
      _highwayStartTime = null;
    }
  } // конец метода _checkCfvDisqualification

  void _checkTakeoffPattern() {
    if (_currentState == FlightState.inFlight) return; // Задание 3
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

    // Задание 4: В окне топтания скорость SOG должна быть не более стандартного шума GPS (~1 км/ч)
    final double maxNoiseSpeedMs = 1.0 / 3.6; // ~1 км/ч
    bool isQuiet = waitPoints.every((p) => p.speed <= maxNoiseSpeedMs);
    if (!isQuiet) return;

    // Проверяем рост высоты: текущая высота должна быть больше средней высоты топтания
    final avgWaitAltitude = waitPoints.map((p) => p.altitude).reduce((a, b) => a + b) / waitPoints.length;
    if (_buffer.last.altitude <= avgWaitAltitude) return;

    // Паттерн совпал!
    double retroactiveDist = 0.0;
    Duration retroactiveTime = Duration.zero;
    bool foundP1 = false;
    LocationEntity? prev;
    for (var p in _buffer) {
      if (p == p1) foundP1 = true;
      if (foundP1) {
        if (prev != null) {
          retroactiveDist += const latlong2.Distance().as(latlong2.LengthUnit.Meter, latlong2.LatLng(prev.latitude, prev.longitude), latlong2.LatLng(p.latitude, p.longitude));
          retroactiveTime += p.timestamp.difference(prev.timestamp);
        }
        prev = p;
      }
    }
    
    _flights.add(FlightRecord(start: p1, distance: retroactiveDist, duration: retroactiveTime));
    _currentState = FlightState.inFlight;
    onLogEvent?.call(p1.timestamp, p1.latitude, p1.longitude, "Паттерн: Взлет");
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
      
      double overDist = 0.0;
      Duration overTime = Duration.zero;
      bool foundP2 = false;
      LocationEntity? prev;
      for (var p in _buffer) {
        if (p == p2) foundP2 = true;
        if (foundP2) {
          if (prev != null) {
            overDist += const latlong2.Distance().as(latlong2.LengthUnit.Meter, latlong2.LatLng(prev.latitude, prev.longitude), latlong2.LatLng(p.latitude, p.longitude));
            overTime += p.timestamp.difference(prev.timestamp);
          }
          prev = p;
        }
      }
      _flights.last.distance -= overDist;
      _flights.last.duration -= overTime;
      if (_flights.last.distance < 0) _flights.last.distance = 0;
      if (_flights.last.duration.isNegative) _flights.last.duration = Duration.zero;
    }
    _currentState = FlightState.landing;
    onLogEvent?.call(p2.timestamp, p2.latitude, p2.longitude, "Паттерн: Посадка");
  } // конец метода _checkLandingPattern
} // конец класса FlightDetectorPipeline
