// =============================================================================
// Файл:    top_telemetry_bar.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Изолированный слой верхней приборной панели (HUD)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_state.dart';
import '../../../../core/location/vertical_speed_provider.dart';
import '../../../flight_detector/presentation/flight_detector_provider.dart';
import '../../../fuel/application/fuel_provider.dart';
import 'instrument_block.dart';

class TopTelemetryBar extends ConsumerWidget {
  final VoidCallback onFuelTap;

  const TopTelemetryBar({super.key, required this.onFuelTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLocation = ref.watch(locationProvider);
    final currentLocation = asyncLocation.valueOrNull;
    final locationError = asyncLocation.hasError ? asyncLocation.error.toString() : null;

    final detectorState = ref.watch(flightDetectorProvider);
    final fuelState = ref.watch(fuelProvider);
    final vz = ref.watch(verticalSpeedProvider);
    
    final dataSource = ref.watch(dataSourceProvider);
    final gpxStateAsync = ref.watch(gpxPointsProvider);
    final gpxState = gpxStateAsync.valueOrNull;

    final vzSign = vz > 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Stack(
        children: [
          // Левая колонка (SOG, FLT, DIST)
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InstrumentBlock(
                  title: 'SOG',
                  unit: 'km/h',
                  value: currentLocation != null
                      ? (currentLocation.speed * 3.6).toStringAsFixed(1)
                      : '--.-',
                ),
                InstrumentBlock(
                  title: 'FLT',
                  unit: 'time',
                  value: detectorState.currentDuration.inHours > 0 
                      ? '${detectorState.currentDuration.inHours}:${(detectorState.currentDuration.inMinutes % 60).toString().padLeft(2, '0')}'
                      : '${(detectorState.currentDuration.inMinutes).toString().padLeft(2, '0')}:${(detectorState.currentDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                ),
                InstrumentBlock(
                  title: 'DIST',
                  unit: 'km',
                  value: (detectorState.currentDistance / 1000.0).toStringAsFixed(1),
                ),
              ],
            ),
          ),
          
          // Правая колонка (ALT, Vz, FUEL)
          Align(
            alignment: Alignment.topRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                InstrumentBlock(
                  title: 'ALT',
                  unit: 'm',
                  value: currentLocation != null
                      ? currentLocation.altitude.toStringAsFixed(0)
                      : '---',
                ),
                InstrumentBlock(
                  title: 'Vz',
                  unit: 'm/s',
                  value: currentLocation != null ? '$vzSign${vz.toStringAsFixed(1)}' : '---',
                ),
                if (fuelState.enableFuelTracking)
                  InstrumentBlock(
                    title: 'FUEL',
                    unit: 'L',
                    value: fuelState.remainder.toStringAsFixed(1),
                    onTap: onFuelTap,
                    isFlashing: fuelState.remainder <= fuelState.jokerRemainder,
                  ),
              ],
            ),
          ),

          // Центральная колонка (BRG, Ошибки, Прогресс загрузки GPX)
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InstrumentBlock(
                  title: 'BRG',
                  unit: '°',
                  value: currentLocation != null
                      ? currentLocation.heading.toStringAsFixed(0)
                      : '---',
                ),
                if (locationError != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.withAlpha(200),
                    child: Text(
                      'Ошибка: $locationError',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                if ((gpxState == null || !gpxState.isDone) && dataSource == DataSource.simulator)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(150),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: gpxState?.progress ?? 0.0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(200),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            'Загрузка трека... ${((gpxState?.progress ?? 0.0) * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}