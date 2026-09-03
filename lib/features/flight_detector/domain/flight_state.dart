// Версия: 0.1.0 | Цель: Модели состояний детектора полета

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

  FlightRecord({required this.start, this.finish, this.isMidAirStart = false});
} // конец класса FlightRecord
