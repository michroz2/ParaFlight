// Версия: 0.5.0 | Цель: Главный экран с линейными контролами и умным компасом ветра

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'dart:async';
import 'dart:math';

import '../../../core/location/location_state.dart';
import '../../../core/location/flight_path_state.dart';
import '../../wind/presentation/wind_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/application/map_settings_provider.dart';
import 'widgets/instrument_block.dart';
import 'widgets/wind_circle_painter.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  MapRotationMode? _rotationMode;
  
  bool _showOverlays = false;
  Timer? _hideTimer;
  
  bool _isFreePanMode = false;
  bool _isTrackingPilot = true;
  Timer? _autoReturnTimer;

  // Переменная для настройки скорости возврата (в миллисекундах)
  final int _mapReturnAnimationMs = 1000;

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: Duration(milliseconds: _mapReturnAnimationMs), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
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

  Widget _buildControlButton(IconData icon, VoidCallback onPressed, {bool isActive = false}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xDD333333),
          border: Border.all(color: isActive ? Colors.blue : Colors.white60, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: isActive ? Colors.blue : Colors.white, size: 36),
      ),
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
    final locationError = asyncLocation.hasError ? asyncLocation.error.toString() : null;
    final dataSource = ref.watch(dataSourceProvider);
    
    final playbackState = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);
    
    final wind = ref.watch(windProvider);

    // Радарная математика (расчет метров на пиксель)
    final standardRadii = <double>[100, 250, 500, 1000, 2000, 5000, 10000, 25000, 50000];
    final earthCircumference = 40075016.686;
    final lat = currentLocation?.latitude ?? 0.0;
    
    // Безопасное получение zoom
    double currentZoom = 13.0;
    try { currentZoom = _mapController.camera.zoom; } catch (_) {}
    
    final metersPerPixel = (earthCircumference * cos(lat * pi / 180.0)) / (256.0 * pow(2, currentZoom));
    
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

    ref.listen(locationProvider, (previous, nextAsync) {
      final next = nextAsync.valueOrNull;
      if (next != null) {
        try {
          if (_isTrackingPilot) {
            double z = 13.0;
            try { z = _mapController.camera.zoom; } catch (_) {}
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

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLocation != null 
                  ? LatLng(currentLocation.latitude, currentLocation.longitude) 
                  : const LatLng(0, 0),
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: _onMapTap,
              onMapReady: () {
                final loc = ref.read(locationProvider).valueOrNull;
                if (loc != null && _isTrackingPilot) {
                  _mapController.move(LatLng(loc.latitude, loc.longitude), _mapController.camera.zoom);
                }
              },
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                if (hasGesture) {
                  if (_isTrackingPilot) setState(() => _isTrackingPilot = false);
                  if (!_isFreePanMode) {
                    _autoReturnTimer?.cancel();
                    _autoReturnTimer = Timer(Duration(seconds: mapSettings.mapAutoCenterSeconds), () {
                      if (mounted) {
                        setState(() => _isTrackingPilot = true);
                        final loc = ref.read(locationProvider).valueOrNull;
                        if (loc != null) {
                          _animatedMapMove(LatLng(loc.latitude, loc.longitude), _mapController.camera.zoom);
                        }
                      }
                    });
                  }
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.paraflight',
              ),
              if (track.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: track,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              if (currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(currentLocation.latitude, currentLocation.longitude),
                      child: Transform.rotate(
                        angle: currentLocation.heading * pi / 180.0,
                        child: const Icon(Icons.flight, color: Colors.red, size: 32),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Фиксированный по центру экранный круг ветра
          if (wind != null)
            IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: windCircleDiameter + 150,
                  height: windCircleDiameter + 150,
                  child: CustomPaint(
                    painter: WindCirclePainter(
                      windDirection: wind.windDirection,
                      windSpeed: wind.windSpeed,
                      mapRotation: _rotationMode == MapRotationMode.heading ? (currentLocation?.heading ?? 0.0) : 0.0,
                      diameter: windCircleDiameter,
                      scaleText: scaleText,
                      showNorthPointer: _rotationMode == MapRotationMode.heading,
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
                          value: currentLocation != null ? (currentLocation.speed * 3.6).toStringAsFixed(1) : '--.-',
                        ),
                        const InstrumentBlock(title: 'FLT', unit: 'time', value: '00:00'),
                        const InstrumentBlock(title: 'DIST', unit: 'km', value: '0.0'),
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
                          value: currentLocation != null ? currentLocation.altitude.toStringAsFixed(0) : '---',
                        ),
                        const InstrumentBlock(title: 'Vz', unit: 'm/s', value: '+0.0'),
                        const InstrumentBlock(title: 'FUEL', unit: 'L', value: '--.-'),
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
                          value: currentLocation != null ? currentLocation.heading.toStringAsFixed(0) : '---',
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
            ),
          ),
          if (wind != null)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: _showOverlays ? (dataSource == DataSource.simulator ? 230 : 100) : (dataSource == DataSource.simulator ? 140 : 20),
              left: 16,
              child: Card(
                color: Colors.white.withAlpha(220),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.air, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text('Ветер: ${wind.windSpeed.toStringAsFixed(1)} м/с', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          Transform.rotate(
                            angle: (wind.windDirection + 180) * pi / 180.0,
                            child: const Icon(Icons.arrow_upward, size: 16, color: Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          Text('Направление: ${wind.windDirection.toStringAsFixed(0)}°'),
                        ],
                      ),
                      Text('Airspeed: ${wind.airspeed.toStringAsFixed(1)} м/с'),
                      Text('RMSE: ${wind.rmse.toStringAsFixed(2)} м/с', style: const TextStyle(fontSize: 14, color: Colors.red)),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xDD333333),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => playbackNotifier.togglePlay(),
                      child: Icon(
                        playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
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
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                            ),
                            child: Slider(
                              value: playbackState.progress,
                              activeColor: Colors.blueAccent,
                              inactiveColor: Colors.white24,
                              onChanged: (value) => playbackNotifier.seek(value),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(playbackState.currentDuration), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                              Text(_formatDuration(playbackState.totalDuration), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        double nextSpeed = playbackState.speedFactor == 1.0 ? 2.0 :
                                           playbackState.speedFactor == 2.0 ? 5.0 :
                                           playbackState.speedFactor == 5.0 ? 10.0 : 1.0;
                        playbackNotifier.setSpeed(nextSpeed);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${playbackState.speedFactor.toInt()}x', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
            bottom: _showOverlays ? (dataSource == DataSource.simulator ? 90 : 20) : -100,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildControlButton(Icons.remove, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
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
                        if (loc != null) _animatedMapMove(LatLng(loc.latitude, loc.longitude), _mapController.camera.zoom);
                      }
                    });
                    _resetUiTimer();
                  },
                  isActive: !_isFreePanMode, // Синяя, когда включено авто-слежение
                ),
                _buildControlButton(
                  _rotationMode == MapRotationMode.heading ? Icons.navigation : Icons.explore,
                  () {
                    setState(() {
                      _rotationMode = _rotationMode == MapRotationMode.north ? MapRotationMode.heading : MapRotationMode.north;
                      if (_rotationMode == MapRotationMode.north) _mapController.rotate(0);
                    });
                    _resetUiTimer();
                  },
                  isActive: _rotationMode == MapRotationMode.heading, // Синяя, когда по курсу
                ),
                _buildControlButton(Icons.add, () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
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
                      const Text(
                        'ParaFlight',
                        style: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                      const Spacer(),
                      IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.settings, color: Colors.black87),
                        onPressed: () {
                          _hideTimer?.cancel();
                          setState(() => _showOverlays = false);
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
    );
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0) return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
  return "$twoDigitMinutes:$twoDigitSeconds";
}
