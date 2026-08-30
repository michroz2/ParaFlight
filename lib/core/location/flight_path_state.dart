// Версия: 0.1.2 | Цель: Провайдер пути полета

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'location_state.dart';

// Новое: реактивный срез пути
final flightPathProvider = Provider<List<LatLng>>((ref) {
  final pointsFuture = ref.watch(gpxPointsProvider);
  final points = pointsFuture.valueOrNull;
  
  if (points == null || points.isEmpty) {
    return [];
  } // конец if
  
  final currentIndex = ref.watch(playbackProvider.select((s) => s.currentIndex));
  
  return points.sublist(0, currentIndex + 1).map((e) => LatLng(e.latitude, e.longitude)).toList();
}); // конец flightPathProvider
