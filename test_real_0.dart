import 'dart:io';
import 'lib/core/location/gpx_parser.dart';

void main() {
  try {
    final xmlString = File('assets/mock_flight.gpx').readAsStringSync();
    final points = GpxParser.parse(xmlString, smoothingWindow: 0);
    print('SUCCESS: ' + points.length.toString() + ' points parsed.');
  } catch (e, stack) {
    print('ERROR: ' + e.toString());
    print(stack.toString());
  }
}
