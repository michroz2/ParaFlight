// Версия: 0.1.0 | Цель: Провайдер детектора полета

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/location/location_state.dart';
import '../../../core/location/location_entity.dart';
import '../domain/flight_state.dart';
import '../application/flight_detector_pipeline.dart';
import 'track_config_provider.dart';

import '../../wind/presentation/wind_provider.dart';
import '../../wind/domain/wind_models.dart';
import '../../../core/telemetry_logger.dart';

class FlightDetectorState {
  final FlightState state;
  final List<FlightRecord> flights;
  final double currentDistance;
  final Duration currentDuration;

  const FlightDetectorState({
    this.state = FlightState.groundMovement,
    this.flights = const [],
    this.currentDistance = 0.0,
    this.currentDuration = Duration.zero,
  });
  
  LocationEntity? get startMark => flights.isNotEmpty ? flights.last.start : null;
  LocationEntity? get finishMark => flights.isNotEmpty ? flights.last.finish : null;
} // конец класса FlightDetectorState

class FlightDetectorNotifier extends StateNotifier<FlightDetectorState> {
  final FlightDetectorPipeline _pipeline;
  final List<LocationEntity> Function() _getPoints;
  final int Function() _getCurrentIndex;
  DateTime? _lastTimestamp;
  
  FlightDetectorNotifier(
    this._pipeline, {
    required List<LocationEntity> Function() getPoints,
    required int Function() getCurrentIndex,
  })  : _getPoints = getPoints,
         _getCurrentIndex = getCurrentIndex,
        super(const FlightDetectorState());

  void updateLocation(LocationEntity location, bool isSimulator, WindCalculationResult? currentWind) {
    bool isJump = false;
    if (_lastTimestamp != null) {
      final diff = location.timestamp.difference(_lastTimestamp!).inMilliseconds;
      if (diff < 0 || diff > 2000) {
        isJump = true;
      }
    }
    _lastTimestamp = location.timestamp;

    if (isJump) {
      // При перемотке сбрасываем и пересобираем состояние
      _pipeline.reset();
      
      if (isSimulator) {
        final allPoints = _getPoints();
        final currentIndex = _getCurrentIndex();
        
        if (allPoints.isNotEmpty && currentIndex >= 0 && currentIndex < allPoints.length) {
          for (int i = 0; i <= currentIndex; i++) {
            _pipeline.processLocation(allPoints[i], currentWind: null); // При перемотке ветер не пересчитываем для CFV
          }
        }
      }

      state = FlightDetectorState(
        state: _pipeline.currentState,
        flights: List.of(_pipeline.flights),
        currentDistance: _pipeline.currentDistance,
        currentDuration: _pipeline.currentDuration,
      );
    } else {
      _pipeline.processLocation(location, currentWind: currentWind);
      state = FlightDetectorState(
        state: _pipeline.currentState,
        flights: List.of(_pipeline.flights),
        currentDistance: _pipeline.currentDistance,
        currentDuration: _pipeline.currentDuration,
      );
    } // конец if-else
  } // конец метода updateLocation

  void clear() {
    _pipeline.reset();
    _lastTimestamp = null;
    state = const FlightDetectorState();
  } // конец метода clear
} // конец класса FlightDetectorNotifier

final StateNotifierProvider<FlightDetectorNotifier, FlightDetectorState> flightDetectorProvider = StateNotifierProvider<FlightDetectorNotifier, FlightDetectorState>((ref) {
  final config = ref.watch(trackConfigProvider);
  final pipeline = FlightDetectorPipeline(
    config: config,
    onLogEvent: (time, lat, lon, reason) {
      ref.read(telemetryProvider.notifier).logEvent(time, LatLng(lat, lon), reason);
    },
  );
  
  final notifier = FlightDetectorNotifier(
    pipeline,
    getPoints: () => ref.read(playbackProvider.notifier).points,
    getCurrentIndex: () => ref.read(playbackProvider).currentIndex,
  );

  ref.listen(locationProvider, (previous, asyncLocation) {
    final location = asyncLocation.valueOrNull;
    if (location != null && ref.read(dataSourceProvider) == DataSource.simulator) {
      final currentWind = ref.read(windProvider);
      notifier.updateLocation(
        location,
        true,
        currentWind,
      );
    }
  });

  ref.listen(dataSourceProvider, (previous, next) {
    if (previous != next) {
      notifier.clear();
      ref.read(telemetryProvider.notifier).clear();
    }
  });

  ref.listen(gpxPointsProvider, (previous, next) {
    notifier.clear();
    ref.read(telemetryProvider.notifier).clear();
  });

  return notifier;
});
