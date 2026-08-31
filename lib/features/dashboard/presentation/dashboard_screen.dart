// Версия: 0.1.2 | Цель: Главный экран панели приборов

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

import '../../../core/location/location_state.dart';
import '../../../core/location/flight_path_state.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
} // конец класса DashboardScreen

enum MapRotationMode { north, free, heading }

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final MapController _mapController = MapController();
  MapRotationMode _rotationMode = MapRotationMode.north;

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(flightPathProvider);
    // Изменение: использование locationProvider вместо locationStreamProvider
    final currentLocation = ref.watch(locationProvider);
    
    // Новое: состояние и нотифайер плеера
    final playbackState = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);

    ref.listen(locationProvider, (previous, next) {
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
      appBar: AppBar(
        title: const Text('ParaFlight'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(0, 0),
              initialZoom: 13.0,
              interactionOptions: InteractionOptions(
                flags: _rotationMode == MapRotationMode.free 
                    ? InteractiveFlag.all 
                    : InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
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
              if (track.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: track.last,
                      child: Transform.rotate(
                        angle: currentLocation != null ? currentLocation.heading * pi / 180.0 : 0.0,
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
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white.withAlpha(220),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: currentLocation != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text('Высота: ${currentLocation.altitude.toStringAsFixed(1)} м'),
                          Text('Скорость: ${currentLocation.speed.toStringAsFixed(1)} м/с'),
                          Text('Курс: ${currentLocation.heading.toStringAsFixed(1)}°'),
                        ],
                      )
                    : const Center(child: Text('Ожидание данных...')),
              ),
            ),
          ),
          // Новое: Кнопка компаса
          Positioned(
            top: 120,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white.withAlpha(220),
              onPressed: () {
                setState(() {
                  switch (_rotationMode) {
                    case MapRotationMode.north:
                      _rotationMode = MapRotationMode.free;
                      break;
                    case MapRotationMode.free:
                      _rotationMode = MapRotationMode.heading;
                      if (currentLocation != null) {
                        _mapController.rotate(360.0 - currentLocation.heading);
                      }
                      break;
                    case MapRotationMode.heading:
                      _rotationMode = MapRotationMode.north;
                      _mapController.rotate(0);
                      break;
                  }
                });
              },
              child: Icon(
                _rotationMode == MapRotationMode.north
                    ? Icons.explore
                    : _rotationMode == MapRotationMode.free
                        ? Icons.screen_rotation
                        : Icons.navigation,
                color: Colors.blue,
              ),
            ),
          ),
          // Новое: Панель управления воспроизведением
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
        ],
      ),
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
