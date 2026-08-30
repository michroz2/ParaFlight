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
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(flightPathProvider);
    final currentLocation = ref.watch(locationStreamProvider);

    ref.listen(locationStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        _mapController.move(
          LatLng(next.value!.latitude, next.value!.longitude),
          15.0,
        );
      }
    });

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
                child: currentLocation.when(
                  data: (data) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Высота: ${data.altitude.toStringAsFixed(1)} м'),
                      Text('Скорость: ${data.speed.toStringAsFixed(1)} м/с'),
                      Text('Курс: ${data.heading.toStringAsFixed(1)}°'),
                    ],
                  ),
                  loading: () => const Center(child: Text('Ожидание данных...')),
                  error: (err, stack) => Center(child: Text('Ошибка: $err')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
