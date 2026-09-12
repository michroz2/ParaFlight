// =============================================================================
// Файл:    wind_compass_overlay.dart
// Проект:  ParaFlight
// Версия:  1.20.5
// Цель:    Изолированный слой отрисовки радара и компаса ветра
// Изменения:
//   1.20.2 - Улучшен расчет амбиентного ветра. Собирается Минимальный рабочий буфер. Если расчеты дают некорректные ошибки, буфер очищается.
//   1.20.5 - Замена isStale на isValid
// =============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
    final wind = ref.watch(windProvider).mapResult;
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

    // Новое: Вычисление указателя на старт
    final flights = ref.watch(flightDetectorProvider).flights;
    final startLocEntity = flights.isNotEmpty ? flights.first.start : null;
    
    double? startBearing;
    double? startDistanceKm;

    if (startLocEntity != null && mapSettings.enableStartPointer && currentLocation != null) {
      final startLatLng = LatLng(startLocEntity.latitude, startLocEntity.longitude);
      final currentLatLng = LatLng(currentLocation.latitude, currentLocation.longitude);
      
      bool isVisible = true;
      try {
         isVisible = mapController.camera.visibleBounds.contains(startLatLng);
      } catch (_) {
         // Fallback if camera is not ready
      }
      
      if (!isVisible) {
        const distance = Distance();
        startDistanceKm = distance.as(LengthUnit.Kilometer, currentLatLng, startLatLng);
        startBearing = distance.bearing(currentLatLng, startLatLng);
      }
    }

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
                isValid: wind?.isValid ?? false, // Изменение: Передаем флаг валидности
                startPointerBearing: startBearing, // Новое
                startDistanceKm: startDistanceKm, // Новое
              ),
            ),
          ),
        ),
      ),
    );
  } // конец метода build
} // конец класса WindCompassOverlay