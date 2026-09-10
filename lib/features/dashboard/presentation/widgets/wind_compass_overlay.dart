// =============================================================================
// Файл:    wind_compass_overlay.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Изолированный слой отрисовки радара и компаса ветра
// =============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/location/location_state.dart';
import '../../../flight_detector/presentation/flight_detector_provider.dart';
import '../../../flight_detector/domain/flight_state.dart';
import '../../../wind/presentation/wind_provider.dart';
import '../../../settings/application/map_settings_provider.dart';
import '../../../settings/application/wind_config_provider.dart';
import 'wind_circle_painter.dart';

class WindCompassOverlay extends ConsumerWidget {
  final MapController mapController;
  final double mapCenterOffsetPercent;

  const WindCompassOverlay({
    super.key,
    required this.mapController,
    required this.mapCenterOffsetPercent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final asyncLocation = ref.watch(locationProvider);
    final currentLocation = asyncLocation.valueOrNull;
    final wind = ref.watch(windProvider);
    final flightState = ref.watch(flightDetectorProvider).state;
    final windConfig = ref.watch(windConfigProvider); // Новое: Читаем конфиг ветра
    final mapSettings = ref.watch(mapSettingsProvider);
    final rotationMode = mapSettings.defaultRotationMode;

    // Радарная математика (расчет метров на пиксель)
    final standardRadii = <double>[
      10, 25, 50, 100, 250, 500, 1000, 2000, 5000, 10000, 25000, 50000,
    ];
    final earthCircumference = 40075016.686;
    final lat = currentLocation?.latitude ?? 0.0;

    double currentZoom = 13.0;
    try {
      currentZoom = mapController.camera.zoom;
    } catch (_) {}

    final metersPerPixel = (earthCircumference * cos(lat * pi / 180.0)) /
        (256.0 * pow(2, currentZoom));

    final targetPixelRadius = min(screenSize.width, screenSize.height) / 4.0;
    final targetMeters = targetPixelRadius * metersPerPixel;

    double bestRadiusMeters = standardRadii.first;
    double minDiff = double.infinity;
    for (var r in standardRadii) {
      final diff = (r - targetMeters).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestRadiusMeters = r;
      }
    } // конец for

    final actualPixelRadius = bestRadiusMeters / metersPerPixel;
    final windCircleDiameter = actualPixelRadius * 2;
    String scaleText = bestRadiusMeters >= 1000
        ? '${(bestRadiusMeters / 1000).toStringAsFixed(bestRadiusMeters % 1000 == 0 ? 0 : 1)} km'
        : '${bestRadiusMeters.toStringAsFixed(0)} m';

    return IgnorePointer(
      child: Center(
        child: Transform.translate(
          offset: Offset(0, screenSize.height * (mapCenterOffsetPercent / 2)),
          child: SizedBox(
            width: windCircleDiameter + 150,
            height: windCircleDiameter + 150,
            child: CustomPaint(
              painter: WindCirclePainter(
                // Изменение: Стрелка показывается только в полете И если включен тумблер
                windDirection: (flightState == FlightState.inFlight && windConfig.enableWindArrow)
                    ? wind?.windDirection
                    : null,
                windSpeed: flightState == FlightState.inFlight
                    ? wind?.windSpeed
                    : null,
                mapRotation: rotationMode == MapRotationMode.heading
                    ? (currentLocation?.heading ?? 0.0)
                    : 0.0,
                diameter: windCircleDiameter,
                scaleText: scaleText,
                showNorthPointer: rotationMode == MapRotationMode.heading,
              ),
            ),
          ),
        ),
      ),
    );
  } // конец метода build
} // конец класса WindCompassOverlay