// Версия: 0.5.0 | Цель: Главный экран с линейными контролами и умным компасом ветра

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'dart:async';
import 'dart:math';

import '../../../core/location/location_state.dart';
import '../../../core/location/flight_path_state.dart';
import '../../../core/location/gpx_writer.dart';
import '../../../core/version_provider.dart';
import '../../flight_detector/presentation/flight_detector_provider.dart'; // Новое: импорт провайдера
import '../../flight_detector/presentation/track_config_provider.dart';
import '../../flight_detector/domain/flight_state.dart';
import '../../../core/telemetry_logger.dart';
import '../../wind/presentation/wind_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/application/map_settings_provider.dart';
import 'widgets/instrument_block.dart';
import 'widgets/wind_circle_painter.dart';
import 'widgets/save_track_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  MapRotationMode? _rotationMode;

  bool _showOverlays = false;
  Timer? _hideTimer;

  bool _isFreePanMode = false;
  bool _isTrackingPilot = true;
  bool? _userPreviewToggle;
  Timer? _autoReturnTimer;

  // Переменная для настройки скорости возврата (в миллисекундах)
  final int _mapReturnAnimationMs = 1000;

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: Duration(milliseconds: _mapReturnAnimationMs),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _autoReturnTimer?.cancel();
    super.dispose();
  }

  void _resetUiTimer() {
    _hideTimer?.cancel();
    if (_showOverlays) {
      final uiHideSeconds = ref.read(mapSettingsProvider).uiAutoHideSeconds;
      _hideTimer = Timer(Duration(seconds: uiHideSeconds), () {
        if (mounted) setState(() => _showOverlays = false);
      });
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _showOverlays = !_showOverlays);
    _resetUiTimer();
  }

  Widget _buildControlButton(
    IconData icon,
    VoidCallback onPressed, {
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xDD333333),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.white60,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.blue : Colors.white,
          size: 36,
        ),
      ),
    );
  }

  void _showTelemetrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Telemetry Logs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(telemetryProvider.notifier).clear(),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final logs = ref.watch(telemetryProvider);
                    if (logs.isEmpty)
                      return const Center(child: Text('No logs'));
                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final event = logs[index];
                        final timeStr =
                            "${event.time.hour.toString().padLeft(2, '0')}:${event.time.minute.toString().padLeft(2, '0')}:${event.time.second.toString().padLeft(2, '0')}";
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            "#[${event.id}] [$timeStr] - ${event.reason}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapSettings = ref.watch(mapSettingsProvider);
    if (_rotationMode == null) {
      _rotationMode = mapSettings.defaultRotationMode;
    }

    final screenSize = MediaQuery.of(context).size;
    final track = ref.watch(flightPathProvider);
    final asyncLocation = ref.watch(locationProvider);
    final gpxStateAsync = ref.watch(gpxPointsProvider);
    final gpxState = gpxStateAsync.valueOrNull;
    final currentLocation = asyncLocation.valueOrNull;
    final locationError = asyncLocation.hasError
        ? asyncLocation.error.toString()
        : null;
    final dataSource = ref.watch(dataSourceProvider);

    final playbackState = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);

    final wind = ref.watch(windProvider);

    // Радарная математика (расчет метров на пиксель)
    final standardRadii = <double>[
      10,
      25,
      50,
      100,
      250,
      500,
      1000,
      2000,
      5000,
      10000,
      25000,
      50000,
    ];
    final earthCircumference = 40075016.686;
    final lat = currentLocation?.latitude ?? 0.0;

    // Безопасное получение zoom
    double currentZoom = 13.0;
    try {
      currentZoom = _mapController.camera.zoom;
    } catch (_) {}

    final metersPerPixel =
        (earthCircumference * cos(lat * pi / 180.0)) /
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
    }

    final actualPixelRadius = bestRadiusMeters / metersPerPixel;
    final windCircleDiameter = actualPixelRadius * 2;
    String scaleText = bestRadiusMeters >= 1000
        ? '${(bestRadiusMeters / 1000).toStringAsFixed(bestRadiusMeters % 1000 == 0 ? 0 : 1)} km'
        : '${bestRadiusMeters.toStringAsFixed(0)} m';

    ref.listen(playbackProvider, (previous, next) {
      if (previous?.hasStarted == true && next.hasStarted == false) {
        setState(() {
          _userPreviewToggle = null;
        });
      }
    });

    ref.listen(locationProvider, (previous, nextAsync) {
      final next = nextAsync.valueOrNull;
      if (next != null) {
        try {
          if (_isTrackingPilot) {
            double z = 13.0;
            try {
              z = _mapController.camera.zoom;
            } catch (_) {}
            _mapController.move(LatLng(next.latitude, next.longitude), z);
          }
          if (_rotationMode == MapRotationMode.heading) {
            _mapController.rotate(360.0 - next.heading);
          }
        } catch (e) {
          // Игнорируем ошибку
        }
      }
    });

    return WillPopScope(
      onWillPop: () async {
        final currentSource = ref.read(dataSourceProvider);
        if (currentSource == DataSource.internalGps) {
          final rawPoints = ref.read(realGpsTrackProvider);
          if (rawPoints.isNotEmpty) {
            final flightDetectorState = ref.read(flightDetectorProvider);
            final result = await showDialog<Map<String, dynamic>>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => SaveTrackDialog(
                flightCount: flightDetectorState.flights.length,
                totalPoints: rawPoints.length,
              ),
            );

            if (result != null) {
              final config = ref.read(trackConfigProvider);
              await GpxWriter.saveTrack(
                rawPoints: rawPoints,
                flights: flightDetectorState.flights,
                cleanUpExtra: result['cleanUpExtra'],
                splitFlights: result['splitFlights'],
                cleanupExtraSec: config.gpsCleanupExtraSec,
              );
            }
          }
        }

        // Позволяем системе выйти (закрыть экран)
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentLocation != null
                    ? LatLng(
                        currentLocation.latitude,
                        currentLocation.longitude,
                      )
                    : const LatLng(0, 0),
                initialZoom: 13.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onTap: _onMapTap,
                onMapReady: () {
                  final loc = ref.read(locationProvider).valueOrNull;
                  if (loc != null && _isTrackingPilot) {
                    _mapController.move(
                      LatLng(loc.latitude, loc.longitude),
                      _mapController.camera.zoom,
                    );
                  }
                },
                onPositionChanged: (MapCamera camera, bool hasGesture) {
                  if (hasGesture) {
                    if (_isTrackingPilot)
                      setState(() => _isTrackingPilot = false);
                    if (!_isFreePanMode) {
                      _autoReturnTimer?.cancel();
                      _autoReturnTimer = Timer(
                        Duration(seconds: mapSettings.mapAutoCenterSeconds),
                        () {
                          if (mounted) {
                            setState(() => _isTrackingPilot = true);
                            final loc = ref.read(locationProvider).valueOrNull;
                            if (loc != null) {
                              _animatedMapMove(
                                LatLng(loc.latitude, loc.longitude),
                                _mapController.camera.zoom,
                              );
                            }
                          }
                        },
                      );
                    }
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.paraflight',
                ),
                if (isPreviewVisible && gpxState != null && gpxState.points != null && dataSource == DataSource.simulator)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: gpxState.points!.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                        color: Colors.purple,
                        strokeWidth: 3.0,
                      )
                    ],
                  ),
                if ((playbackState.hasStarted || dataSource == DataSource.internalGps) && track.isNotEmpty)
                  PolylineLayer(
                    polylines: track.map((segment) {
                      return Polyline(
                        points: segment.points,
                        color: segment.isFlight ? Colors.blue : Colors.grey,
                        strokeWidth: segment.isFlight ? 4.0 : 2.0,
                      );
                    }).toList(),
                  ),
                // Новое: слой маркеров для старта и финиша
                if (playbackState.hasStarted || dataSource == DataSource.internalGps)
                  Builder(
                    builder: (context) {
                      final detectorState = ref.watch(flightDetectorProvider);
                      final markers = <Marker>[];
                      final flights = detectorState.flights;
                      for (int i = 0; i < flights.length; i++) {
                        final flight = flights[i];
                        // Маркер старта: первый полет 'S', остальные 'R'. Забытый старт в воздухе - 'O'
                        final startChar = flight.isMidAirStart
                            ? 'O'
                            : (i == 0 ? 'S' : 'R');
                        markers.add(
                          Marker(
                            point: LatLng(
                              flight.start.latitude,
                            flight.start.longitude,
                          ),
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(200),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blue, width: 2),
                            ),
                            child: Text(
                              startChar,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      );

                      // Маркер финиша (если есть)
                      if (flight.finish != null) {
                        markers.add(
                          Marker(
                            point: LatLng(
                              flight.finish!.latitude,
                              flight.finish!.longitude,
                            ),
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(200),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: const Text(
                                'X',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    } // конец for
                    if (markers.isEmpty) return const SizedBox.shrink();
                    return MarkerLayer(markers: markers);
                  },
                ),
                if (playbackState.hasStarted || dataSource == DataSource.internalGps)
                  Builder(
                    builder: (context) {
                      final config = ref.watch(trackConfigProvider);
                      if (!config.enableDebugMarkers) return const SizedBox.shrink();
                      final logs = ref.watch(telemetryProvider);
                    if (logs.isEmpty) return const SizedBox.shrink();
                    final markers = logs.map((event) {
                      return Marker(
                        point: event.location,
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(200),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            event.id.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              height: 1.0,
                            ),
                          ),
                        ),
                      );
                    }).toList();
                    return MarkerLayer(markers: markers);
                  },
                ),
                if (currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          currentLocation.latitude,
                          currentLocation.longitude,
                        ),
                        child: Transform.rotate(
                          angle: currentLocation.heading * pi / 180.0,
                          child: const Icon(
                            Icons.flight,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Фиксированный по центру экранный круг ветра
            IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: windCircleDiameter + 150,
                  height: windCircleDiameter + 150,
                  child: CustomPaint(
                    painter: WindCirclePainter(
                      windDirection:
                          ref.watch(flightDetectorProvider).state ==
                              FlightState.inFlight
                          ? wind?.windDirection
                          : null,
                      windSpeed:
                          ref.watch(flightDetectorProvider).state ==
                              FlightState.inFlight
                          ? wind?.windSpeed
                          : null,
                      mapRotation: _rotationMode == MapRotationMode.heading
                          ? (currentLocation?.heading ?? 0.0)
                          : 0.0,
                      diameter: windCircleDiameter,
                      scaleText: scaleText,
                      showNorthPointer:
                          _rotationMode == MapRotationMode.heading,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Stack(
                  children: [
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
                                ? (currentLocation.speed * 3.6).toStringAsFixed(
                                    1,
                                  )
                                : '--.-',
                          ),
                          const InstrumentBlock(
                            title: 'FLT',
                            unit: 'time',
                            value: '00:00',
                          ),
                          const InstrumentBlock(
                            title: 'DIST',
                            unit: 'km',
                            value: '0.0',
                          ),
                        ],
                      ),
                    ),
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
                          const InstrumentBlock(
                            title: 'Vz',
                            unit: 'm/s',
                            value: '+0.0',
                          ),
                          const InstrumentBlock(
                            title: 'FUEL',
                            unit: 'L',
                            value: '--.-',
                          ),
                        ],
                      ),
                    ),
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if ((gpxState == null || !gpxState.isDone) &&
                              dataSource == DataSource.simulator)
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
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
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
              ),
            ),
            if (wind != null &&
                ref.watch(flightDetectorProvider).state == FlightState.inFlight)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                bottom: _showOverlays
                    ? (dataSource == DataSource.simulator ? 230 : 100)
                    : (dataSource == DataSource.simulator ? 140 : 20),
                left: 16,
                child: Card(
                  color: Colors.white.withAlpha(220),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.air, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Ветер: ${wind.windSpeed.toStringAsFixed(1)} м/с',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Transform.rotate(
                              angle: (wind.windDirection + 180) * pi / 180.0,
                              child: const Icon(
                                Icons.arrow_upward,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Направление: ${wind.windDirection.toStringAsFixed(0)}°',
                            ),
                          ],
                        ),
                        Text(
                          'Airspeed: ${wind.airspeed.toStringAsFixed(1)} м/с',
                        ),
                        Text(
                          'RMSE: ${wind.rmse.toStringAsFixed(2)} м/с',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (dataSource == DataSource.simulator)
              Positioned(
                bottom: 10,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xDD333333),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _userPreviewToggle = !isPreviewVisible;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.gesture,
                            color: isPreviewVisible ? Colors.purpleAccent : Colors.white54,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () => playbackNotifier.togglePlay(),
                        child: Icon(
                          playbackState.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2.0,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6.0,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 12.0,
                                ),
                              ),
                              child: Slider(
                                value: playbackState.progress,
                                activeColor: Colors.blueAccent,
                                inactiveColor: Colors.white24,
                                onChanged: (value) =>
                                    playbackNotifier.seek(value),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(
                                    playbackState.currentDuration,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  _formatDuration(playbackState.totalDuration),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          double nextSpeed = playbackState.speedFactor == 1.0
                              ? 2.0
                              : playbackState.speedFactor == 2.0
                                  ? 5.0
                                  : playbackState.speedFactor == 5.0
                                      ? 10.0
                                      : playbackState.speedFactor == 10.0
                                          ? 20.0
                                          : playbackState.speedFactor == 20.0
                                              ? 60.0
                                              : 1.0;
                          playbackNotifier.setSpeed(nextSpeed);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${playbackState.speedFactor.toInt()}x',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Панель: Линейная панель управления (Linear Control Bar)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showOverlays
                  ? (dataSource == DataSource.simulator ? 90 : 20)
                  : -100,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildControlButton(Icons.remove, () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                    _resetUiTimer();
                  }),
                  _buildControlButton(
                    _isFreePanMode ? Icons.lock_open : Icons.my_location,
                    () {
                      setState(() {
                        _isFreePanMode = !_isFreePanMode;
                        if (!_isFreePanMode) {
                          _isTrackingPilot = true;
                          final loc = ref.read(locationProvider).valueOrNull;
                          if (loc != null)
                            _animatedMapMove(
                              LatLng(loc.latitude, loc.longitude),
                              _mapController.camera.zoom,
                            );
                        }
                      });
                      _resetUiTimer();
                    },
                    isActive:
                        !_isFreePanMode, // Синяя, когда включено авто-слежение
                  ),
                  _buildControlButton(
                    _rotationMode == MapRotationMode.heading
                        ? Icons.navigation
                        : Icons.explore,
                    () {
                      setState(() {
                        _rotationMode = _rotationMode == MapRotationMode.north
                            ? MapRotationMode.heading
                            : MapRotationMode.north;
                        if (_rotationMode == MapRotationMode.north)
                          _mapController.rotate(0);
                      });
                      _resetUiTimer();
                    },
                    isActive:
                        _rotationMode ==
                        MapRotationMode.heading, // Синяя, когда по курсу
                  ),
                  _buildControlButton(Icons.add, () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                    _resetUiTimer();
                  }),
                ],
              ),
            ),

            // Верхняя панель
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: _showOverlays ? 0 : -100,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.amber,
                elevation: 4,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Consumer(
                          builder: (context, ref, _) {
                            final versionAsync = ref.watch(packageInfoProvider);
                            final versionText = versionAsync.when(
                              data: (info) => ' v${info.version}',
                              loading: () => '',
                              error: (_, __) => '',
                            );
                            return Text(
                              'ParaFlight$versionText',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        Consumer(
                          builder: (context, ref, _) {
                            final config = ref.watch(trackConfigProvider);
                            if (!config.enableDebugMarkers) return const SizedBox.shrink();
                            return IconButton(
                              iconSize: 32,
                              icon: const Icon(
                                Icons.bug_report,
                                color: Colors.black87,
                              ),
                              onPressed: () => _showTelemetrySheet(context),
                            );
                          },
                        ),
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.black87,
                          ),
                          onPressed: () {
                            _hideTimer?.cancel();
                            setState(() => _showOverlays = false);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0)
    return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
  return "$twoDigitMinutes:$twoDigitSeconds";
}
