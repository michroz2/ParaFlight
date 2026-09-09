// =============================================================================
// Файл:    flight_state.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Модели состояний детектора полета
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================

import '../../../core/location/location_entity.dart';

enum FlightState {
  groundMovement,
  takeoff,
  inFlight,
  landing
}

class FlightRecord {
  final LocationEntity start;
  LocationEntity? finish;
  final bool isMidAirStart;
  
  double distance;
  Duration duration;

  FlightRecord({
    required this.start, 
    this.finish, 
    this.isMidAirStart = false,
    this.distance = 0.0,
    this.duration = Duration.zero,
  });
} // конец класса FlightRecord
