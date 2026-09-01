import 'dart:io';
import 'package:xml/xml_events.dart';

void main() {
  final file = File('assets/mock_flight.gpx');
  int count = 0;
  file.openRead()
      .map((bytes) => String.fromCharCodes(bytes)) // crude utf8
      .transform(XmlEventDecoder())
      .transform(XmlNormalizeEvents())
      .listen((events) {
        for (var event in events) {
          if (event is XmlStartElementEvent && event.name == 'trkpt') {
            count++;
          }
        }
      }, onDone: () => print('Found \ trkpts'));
}
