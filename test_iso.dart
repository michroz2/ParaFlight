import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'lib/core/location/location_entity.dart';
import 'lib/core/location/gpx_parser.dart';
void main() async {
  final xmlString = File('assets/mock_flight.gpx').readAsStringSync();
  final receivePort = ReceivePort();
  await Isolate.spawn(parseGpxStreamingIsolate, {
    'sendPort': receivePort.sendPort,
    'xmlString': xmlString,
    'smoothingWindow': 0,
  });
  await for (final msg in receivePort) {
    if (msg is List<LocationEntity>) {
      print(msg.length);
      receivePort.close();
      break;
    }
  }
}
