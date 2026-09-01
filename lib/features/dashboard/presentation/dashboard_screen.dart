// Версия: 0.4.0 | Цель: Главный экран панели приборов (Интеграция скрытого Config UI)

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
import 'widgets/instrument_block.dart';
import 'widgets/wind_circle_painter.dart'; // Новое: компас ветра

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
} // конец класса DashboardScreen

enum MapRotationMode { north, heading }

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final MapController _mapController = MapController();
  MapRotationMode _rotationMode = MapRotationMode.north;

  bool _showSettingsBar = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  } // конец метода dispose

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    setState(() {
      _showSettingsBar = true;
    });
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showSettingsBar = false;
        });
      }
    });
  } // конец метода _onMapLongPress

  @override
  Widget build(BuildContext context) {
    // Новое: размеры экрана для круга ветра
    final screenSize = MediaQuery.of(context).size;
    final windCircleDiameter = min(screenSize.width, screenSize.height) / 2.0;

    final track = ref.watch(flightPathProvider);
    // Изменение: использование locationProvider с AsyncValue
    final asyncLocation = ref.watch(locationProvider);
    final currentLocation = asyncLocation.valueOrNull;
    final locationError = asyncLocation.hasError ? asyncLocation.error.toString() : null;
    final dataSource = ref.watch(dataSourceProvider);
    
    // Новое: состояние и нотифайер плеера
    final playbackState = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);
    
    // ВЕТЕР
    final wind = ref.watch(windProvider);

    ref.listen(locationProvider, (previous, nextAsync) {
      final next = nextAsync.valueOrNull;
      if (next != null) {
        _mapController.move(
          LatLng(next.latitude, next.longitude),
          _mapController.camera.zoom,
        );
        if (_rotationMode == MapRotationMode.heading) {
          _mapController.rotate(360.0 - next.heading);
        }
      } // конец if
    }); // конец замыкания listen

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(0, 0),
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onLongPress: _onMapLongPress,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.paraflight.app',
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
                    // Новое: Маркер с кругом ветра
                    if (wind != null)
                      Marker(
                        point: LatLng(currentLocation.latitude, currentLocation.longitude),
                        width: windCircleDiameter + 100, // с запасом для текста
                        height: windCircleDiameter + 100,
                        child: CustomPaint(
                          painter: WindCirclePainter(
                            windDirection: wind.windDirection,
                            windSpeed: wind.windSpeed,
                            mapRotation: _rotationMode == MapRotationMode.heading ? currentLocation.heading : 0.0,
                            diameter: windCircleDiameter,
                          ),
                        ),
                      ),
                    // Маркер пилота (самолетик)
                    Marker(
                      point: LatLng(currentLocation.latitude, currentLocation.longitude),
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
          // Новое: HUD Слой поверх карты
          SafeArea(
            child: Padding(
              // Изменение: Уменьшены поля от края экрана в 2 раза (было 8.0)
              padding: const EdgeInsets.all(4.0),
              child: Stack(
                children: [
                  // Левая колонка
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
                    ), // конец Column
                  ), // конец Align
                  // Правая колонка
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
                    ), // конец Column
                  ), // конец Align
                  // Центр
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
                          ), // конец Container
                      ],
                    ), // конец Column
                  ), // конец Align
                ],
              ), // конец Stack
            ), // конец Padding
          ), // конец SafeArea
          // Карточка Ветра и Airspeed
          if (wind != null)
            Positioned(
              bottom: dataSource == DataSource.simulator ? 140 : 20, // Изменение: перенесено в левый нижний угол, с учетом плеера
              left: 16,
              child: Card(
                color: Colors.white.withAlpha(220),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.air, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Ветер: ${wind.windSpeed.toStringAsFixed(1)} м/с',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
          // Новое: Кнопка компаса
          Positioned(
            bottom: dataSource == DataSource.simulator ? 140 : 20, // Изменение: перенесено в правый нижний угол
            right: 16,
            child: IconButton(
              iconSize: 36,
              onPressed: () {
                setState(() {
                  if (_rotationMode == MapRotationMode.north) {
                    _rotationMode = MapRotationMode.heading;
                    if (currentLocation != null) {
                      _mapController.rotate(360.0 - currentLocation.heading);
                    }
                  } else {
                    _rotationMode = MapRotationMode.north;
                    _mapController.rotate(0);
                  }
                });
              },
              icon: Transform.rotate(
                angle: _rotationMode == MapRotationMode.heading && currentLocation != null 
                    ? -currentLocation.heading * pi / 180.0 
                    : 0.0,
                child: CustomPaint(
                  size: const Size(14, 32),
                  painter: CompassArrowPainter(),
                ),
              ),
            ),
          ),
          // Новое: Панель управления воспроизведением
          if (dataSource == DataSource.simulator)
            Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.black54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: playbackState.progress,
                    onChanged: (value) {
                      playbackNotifier.seek(value);
                    }, // конец замыкания onChanged
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playbackState.currentDuration),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          _formatDuration(playbackState.totalDuration),
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.fast_rewind, color: Colors.white),
                        onPressed: () {
                          playbackNotifier.seek(0.0);
                        }, // конец замыкания onPressed
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: () {
                          playbackNotifier.setSpeed(max(0.5, playbackState.speedFactor / 2));
                        }, // конец замыкания onPressed
                      ),
                      IconButton(
                        icon: Icon(
                          playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          playbackNotifier.togglePlay();
                        }, // конец замыкания onPressed
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          playbackNotifier.setSpeed(min(16.0, playbackState.speedFactor * 2));
                        }, // конец замыкания onPressed
                      ),
                      Text(
                        'x${playbackState.speedFactor.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Новое: Скрытый бар настроек
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showSettingsBar ? 0 : -100, // Увеличил отступ, чтобы полностью скрыть за SafeArea
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
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.settings, color: Colors.black87),
                        onPressed: () {
                          _hideTimer?.cancel();
                          setState(() {
                            _showSettingsBar = false;
                          });
                          // Переход в настройки
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        }, // конец onPressed
                      ),
                      const SizedBox(width: 8),
                    ],
                  ), // конец Row
                ), // конец SizedBox
              ), // конец SafeArea
            ), // конец Material
          ), // конец AnimatedPositioned
        ],
      ), // конец Stack
    );
  } // конец метода build
} // конец класса _DashboardScreenState

String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0) {
    return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
  }
  return "$twoDigitMinutes:$twoDigitSeconds";
}

class CompassArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final redPath = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(redPath, Paint()..color = Colors.red);

    final whitePath = Path()
      ..moveTo(w / 2, h)
      ..lineTo(w, h / 2)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(whitePath, Paint()..color = Colors.white);

    final borderPath = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(
        borderPath,
        Paint()
          ..color = Colors.grey.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
