import sys
content = open('lib/features/flight_detector/application/flight_detector_pipeline.dart', 'r', encoding='utf-8').read()

# Add _totalTrackDistance, _totalTrackDuration, _lastLocation
content = content.replace('  final List<FlightRecord> _flights = [];', '''  final List<FlightRecord> _flights = [];
  
  double _totalTrackDistance = 0.0;
  Duration _totalTrackDuration = Duration.zero;
  LocationEntity? _lastLocation;''')

# Update reset()
content = content.replace('    _currentState = FlightState.groundMovement;', '''    _currentState = FlightState.groundMovement;
    _totalTrackDistance = 0.0;
    _totalTrackDuration = Duration.zero;
    _lastLocation = null;''')

# Getters for distance/time
content = content.replace('  List<LocationEntity> get buffer => _buffer;', '''  List<LocationEntity> get buffer => _buffer;
  
  double get currentDistance {
    if (_flights.isEmpty) return _totalTrackDistance;
    return _flights.fold(0.0, (sum, f) => sum + f.distance);
  }
  
  Duration get currentDuration {
    if (_flights.isEmpty) return _totalTrackDuration;
    return _flights.fold(Duration.zero, (sum, f) => sum + f.duration);
  }''')

# Update processLocation
old_process = '''  void processLocation(LocationEntity point, {WindCalculationResult? currentWind}) {
    _buffer.add(point);
    
    // Поддерживаем буфер размером 60 секунд'''
new_process = '''  void processLocation(LocationEntity point, {WindCalculationResult? currentWind}) {
    double deltaDist = 0.0;
    Duration deltaT = Duration.zero;
    if (_lastLocation != null) {
      final distance = const latlong2.Distance();
      deltaDist = distance.as(latlong2.LengthUnit.Meter, latlong2.LatLng(_lastLocation!.latitude, _lastLocation!.longitude), latlong2.LatLng(point.latitude, point.longitude));
      deltaT = point.timestamp.difference(_lastLocation!.timestamp);
    }
    _totalTrackDistance += deltaDist;
    _totalTrackDuration += deltaT;
    
    _buffer.add(point);
    
    if (_currentState == FlightState.inFlight && _flights.isNotEmpty) {
      _flights.last.distance += deltaDist;
      _flights.last.duration += deltaT;
    }
    
    // Поддерживаем буфер размером 60 секунд'''
content = content.replace(old_process, new_process)

# Add import
content = content.replace("import '../domain/flight_state.dart';", "import 'package:latlong2/latlong.dart' as latlong2;\nimport '../domain/flight_state.dart';")

# Update _lastLocation = point
content = content.replace('    } // конец if-else\n  } // конец метода processLocation', '    } // конец if-else\n    _lastLocation = point;\n  } // конец метода processLocation')

# Update _checkTakeoffPattern
takeoff_old = '''    // Паттерн совпал!
    _flights.add(FlightRecord(start: p1));
    _currentState = FlightState.inFlight;'''
takeoff_new = '''    // Паттерн совпал!
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
    _currentState = FlightState.inFlight;'''
content = content.replace(takeoff_old, takeoff_new)

# Update _checkMidAirStartPattern
midair_old = '''      if (isHighSpeed) {
        final start = recentPoints.first;
        _flights.add(FlightRecord(start: start, isMidAirStart: true));
        _currentState = FlightState.inFlight;'''
midair_new = '''      if (isHighSpeed) {
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
        _currentState = FlightState.inFlight;'''
content = content.replace(midair_old, midair_new)

# Update _checkLandingPattern
landing_old = '''    // Паттерн совпал!
    if (_flights.isNotEmpty) {
      _flights.last.finish = p2;
    }
    _currentState = FlightState.landing;'''
landing_new = '''    // Паттерн совпал!
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
    _currentState = FlightState.landing;'''
content = content.replace(landing_old, landing_new)

open('lib/features/flight_detector/application/flight_detector_pipeline.dart', 'w', encoding='utf-8').write(content)
