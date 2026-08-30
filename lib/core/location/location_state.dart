import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'location_entity.dart';
import 'simulator_location_provider.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'gpx_parser.dart';

final gpxPointsProvider = FutureProvider<List<LocationEntity>>((ref) async {
  final xmlString = await rootBundle.loadString('assets/mock_flight.gpx');
  return GpxParser.parse(xmlString);
});

/// Провайдер потока данных геолокации, который слушает интерфейс
final locationStreamProvider = StreamProvider<LocationEntity>((ref) async* {
  final points = await ref.watch(gpxPointsProvider.future);
  if (points.isNotEmpty) {
    final simulator = SimulatorLocationProvider(points);
    yield* simulator.locationStream;
  }
});
