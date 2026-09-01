// Версия: 0.1.2 | Цель: Провайдер пути полета

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'location_state.dart';

// Новое: Класс для накопления точек реального GPS
class RealGpsTrackNotifier extends Notifier<List<LatLng>> {
  @override
  List<LatLng> build() {
    // Подписываемся на локацию, добавляем точки только в режиме GPS
    ref.listen(locationProvider, (previous, asyncLocation) {
      final loc = asyncLocation.valueOrNull;
      if (loc != null && ref.read(dataSourceProvider) == DataSource.internalGps) {
        state = [...state, LatLng(loc.latitude, loc.longitude)];
      } // конец if
    });
    return [];
  } // конец метода build
} // конец класса RealGpsTrackNotifier

final realGpsTrackProvider = NotifierProvider<RealGpsTrackNotifier, List<LatLng>>(RealGpsTrackNotifier.new);

// Изменение: Переключатель трека между симулятором и GPS
final flightPathProvider = Provider<List<LatLng>>((ref) {
  final dataSource = ref.watch(dataSourceProvider);
  
  if (dataSource == DataSource.internalGps) {
    return ref.watch(realGpsTrackProvider);
  } // конец if

  // Логика симулятора
  final gpxStateAsync = ref.watch(gpxPointsProvider);
  final gpxState = gpxStateAsync.valueOrNull;
  
  if (gpxState == null || gpxState.points == null || gpxState.points!.isEmpty) {
    return [];
  } // конец if
  
  final points = gpxState.points!;
  
  final currentIndex = ref.watch(playbackProvider.select((s) => s.currentIndex));
  
  return points.sublist(0, currentIndex + 1).map((e) => LatLng(e.latitude, e.longitude)).toList();
}); // конец flightPathProvider
