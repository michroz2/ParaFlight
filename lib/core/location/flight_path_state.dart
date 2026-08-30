import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'location_state.dart';

class FlightPathNotifier extends Notifier<List<LatLng>> {
  @override
  List<LatLng> build() {
    ref.listen(locationStreamProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        final location = next.value!;
        state = [...state, LatLng(location.latitude, location.longitude)];
      }
    });
    
    return [];
  }
}

final flightPathProvider = NotifierProvider<FlightPathNotifier, List<LatLng>>(() {
  return FlightPathNotifier();
});
