// =============================================================================
// Файл:    flight_path_state.dart
// Проект:  ParaFlight
// Версия:  0.1.2
// Цель:    Провайдер пути полета
// Изменения:
//   0.1.2 - Первичная реализация
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'location_state.dart';
import 'location_entity.dart';

import '../../features/flight_detector/presentation/flight_detector_provider.dart';
import '../../features/flight_detector/presentation/track_config_provider.dart';

// Класс для представления сегмента трека
class TrackSegment {
  final List<LatLng> points;
  final bool isFlight;
  TrackSegment({required this.points, required this.isFlight});
}

class RealGpsTrackNotifier extends Notifier<List<LocationEntity>> {
  @override
  List<LocationEntity> build() {
    // Подписываемся на смену источника для очистки трека
    ref.listen(dataSourceProvider, (previous, next) {
      if (next == DataSource.internalGps && previous != next) {
        clear();
      }
    });

    return [];
  } // конец метода build
  
  // Вызывается напрямую из realGpsProvider, чтобы обойти батчинг Riverpod
  void addPoint(LocationEntity loc) {
    final source = ref.read(dataSourceProvider);
    if (source != DataSource.internalGps) return;
    
    // Прореживание теперь выполняется централизованно в realGpsProvider
    debugPrint('RealGpsTrackNotifier | Adding point to state (direct)');
    state = [...state, loc];
  }

  void clear() {
    state = [];
  }
} // конец класса RealGpsTrackNotifier

final realGpsTrackProvider =
    NotifierProvider<RealGpsTrackNotifier, List<LocationEntity>>(
      RealGpsTrackNotifier.new,
    );

// Изменение: Переключатель трека возвращает сегментированный трек
final flightPathProvider = Provider<List<TrackSegment>>((ref) {
  final dataSource = ref.watch(dataSourceProvider);
  List<LatLng> rawPoints = [];

  if (dataSource == DataSource.internalGps) {
    final entities = ref.watch(realGpsTrackProvider);
    rawPoints = entities.map((e) => LatLng(e.latitude, e.longitude)).toList();
  } else {
    // Логика симулятора
    final gpxStateAsync = ref.watch(gpxPointsProvider);
    final gpxState = gpxStateAsync.valueOrNull;

    if (gpxState != null &&
        gpxState.points != null &&
        gpxState.points!.isNotEmpty) {
      final currentIndex = ref.watch(
        playbackProvider.select((s) => s.currentIndex),
      );
      rawPoints = gpxState.points!
          .sublist(0, currentIndex + 1)
          .map((e) => LatLng(e.latitude, e.longitude))
          .toList();
    }
  }

  if (rawPoints.isEmpty) return [];

  final detectorState = ref.watch(flightDetectorProvider);

  // Если нет маркеров, весь трек - это земля (серый)
  if (detectorState.flights.isEmpty) {
    return [TrackSegment(points: rawPoints, isFlight: false)];
  }

  final segments = <TrackSegment>[];
  int currentIndexInRaw = 0;

  for (final flight in detectorState.flights) {
    final startLoc = LatLng(flight.start.latitude, flight.start.longitude);
    int startIndex = rawPoints.indexWhere(
      (p) =>
          p.latitude == startLoc.latitude && p.longitude == startLoc.longitude,
      currentIndexInRaw,
    );

    if (startIndex == -1) continue;

    // Добавляем наземный сегмент ДО этого старта
    if (startIndex > currentIndexInRaw) {
      segments.add(
        TrackSegment(
          points: rawPoints.sublist(currentIndexInRaw, startIndex + 1),
          isFlight: false,
        ),
      );
    }

    if (flight.finish == null) {
      // Полет еще не закончен
      segments.add(
        TrackSegment(points: rawPoints.sublist(startIndex), isFlight: true),
      );
      currentIndexInRaw = rawPoints.length;
      break;
    }

    final finishLoc = LatLng(flight.finish!.latitude, flight.finish!.longitude);
    int finishIndex = rawPoints.indexWhere(
      (p) =>
          p.latitude == finishLoc.latitude &&
          p.longitude == finishLoc.longitude,
      startIndex,
    );

    if (finishIndex == -1 || finishIndex < startIndex) {
      // Финиш не найден или ошибка
      segments.add(
        TrackSegment(points: rawPoints.sublist(startIndex), isFlight: true),
      );
      currentIndexInRaw = rawPoints.length;
      break;
    }

    // Добавляем полетный сегмент
    segments.add(
      TrackSegment(
        points: rawPoints.sublist(startIndex, finishIndex + 1),
        isFlight: true,
      ),
    );
    currentIndexInRaw = finishIndex;
  } // конец for

  // Если остались точки после последнего финиша, это земля
  if (currentIndexInRaw < rawPoints.length - 1) {
    segments.add(
      TrackSegment(
        points: rawPoints.sublist(currentIndexInRaw),
        isFlight: false,
      ),
    );
  }

  return segments;
}); // конец flightPathProvider
