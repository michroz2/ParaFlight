import 'dart:io';
import 'package:xml/xml.dart';

void main() {
  final xmlString = File('assets/mock_flight.gpx').readAsStringSync();
  final document = XmlDocument.parse(xmlString);
  final trkpts = document.findAllElements('trkpt');
  print('Found ' + trkpts.length.toString() + ' track points.');
  if (trkpts.isNotEmpty) {
    final first = trkpts.first;
    print('First point: lat=' + first.getAttribute('lat').toString() + ' lon=' + first.getAttribute('lon').toString());
  }
}
