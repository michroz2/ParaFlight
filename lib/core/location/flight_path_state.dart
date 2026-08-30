// Версия: 0.1.1 | Цель: Провайдер пути полета

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'location_state.dart';

class FlightPathNotifier extends Notifier<List<LatLng>> {
  @override
  List<LatLng> build() {
    // Изменение: прослушивание нового locationProvider
    ref.listen(locationProvider, (previous, next) {
      if (next != null) {
        state = [...state, LatLng(next.latitude, next.longitude)];
      } // конец if
    }); // конец замыкания listen
    
    return [];
  } // конец метода build
} // конец класса FlightPathNotifier

final flightPathProvider = NotifierProvider<FlightPathNotifier, List<LatLng>>(() {
  return FlightPathNotifier();
}); // конец flightPathProvider
