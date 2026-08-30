// Версия: 0.1.1 | Цель: Главный экран панели приборов

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_state.dart';
import '../../../core/location/flight_path_state.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
} // конец класса DashboardScreen

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(flightPathProvider);
    // Изменение: использование locationProvider вместо locationStreamProvider
    final currentLocation = ref.watch(locationProvider);

    ref.listen(locationProvider, (previous, next) {
      if (next != null) {
        _mapController.move(
          LatLng(next.latitude, next.longitude),
          15.0,
        );
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
            options: const MapOptions(
              initialCenter: LatLng(0, 0),
              initialZoom: 13.0,
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
                      child: const Icon(
                        Icons.flight,
                        color: Colors.red,
                        size: 32,
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
        ],
      ),
    );
  } // конец метода build
} // конец класса _DashboardScreenState
