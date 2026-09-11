// =============================================================================
// Файл:    flight_detector_provider.dart
// Проект:  ParaFlight
// Версия:  0.2.0
// Цель:    Провайдер детектора полета
// Изменения:
//   0.1.0 - Первичная реализация
//   0.2.0 - Устранение костылей для перемотки. Переход на единый сигнал seekCount (DRY)
// =============================================================================

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
  
  FlightDetectorNotifier(
    this._pipeline, {
    required this._getPoints,
    required this._getCurrentIndex,
  })  : super(const FlightDetectorState());

  void updateLocation(LocationEntity location, WindCalculationResult? currentWind, {bool useCalculatedSpeed = false}) {
    // Вся логика "прыжков" удалена, слушаем напрямую
    _pipeline.processLocation(location, currentWind: currentWind, useCalculatedSpeed: useCalculatedSpeed);
    state = FlightDetectorState(
      state: _pipeline.currentState,
      flights: List.of(_pipeline.flights),
      currentDistance: _pipeline.currentDistance,
      currentDuration: _pipeline.currentDuration,
    );
  } // конец метода updateLocation

  // Новое: Метод для репроцессинга при прыжках во времени (от слушателя seekCount)
  void reprocessFromStart() {
    _pipeline.reset();
    
    final allPoints = _getPoints();
    final currentIndex = _getCurrentIndex();
    
    if (allPoints.isNotEmpty && currentIndex >= 0 && currentIndex < allPoints.length) {
      for (int i = 0; i <= currentIndex; i++) {
        _pipeline.processLocation(allPoints[i], currentWind: null, useCalculatedSpeed: true); // В симуляторе используем рассчитанную скорость
      }
    }

    state = FlightDetectorState(
      state: _pipeline.currentState,
      flights: List.of(_pipeline.flights),
      currentDistance: _pipeline.currentDistance,
      currentDuration: _pipeline.currentDuration,
    );
  } // конец метода reprocessFromStart

  void clear() {
    _pipeline.reset();
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
    if (location != null) {
      final dataSource = ref.read(dataSourceProvider);
      final currentWind = ref.read(windProvider).mapResult;
      
      // Вычисляем математическую скорость всегда для симулятора, 
      // а для встроенного GPS - только если включен тумблер "Данные эмулятора"
      final useMath = dataSource == DataSource.simulator || ref.read(emulatorDataEnabledProvider);

      notifier.updateLocation(
        location,
        currentWind,
        useCalculatedSpeed: useMath,
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

  // Новое: Слушаем централизованный сигнал перемотки (DRY)
  ref.listen(playbackProvider.select((s) => s.seekCount), (previous, current) {
    if (previous != null && current != previous) {
      if (ref.read(dataSourceProvider) == DataSource.simulator) {
        notifier.reprocessFromStart();
      }
    }
  });

  return notifier;
});
