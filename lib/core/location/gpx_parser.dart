import 'dart:math' as math;
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import 'location_entity.dart';

class GpxParser {
  static List<LocationEntity> parse(String xmlString, {int smoothingWindow = 2}) {
    final document = XmlDocument.parse(xmlString);
    final trkpts = document.findAllElements('trkpt');
    
    final List<LocationEntity> locations = [];
    final distance = const Distance();
    
    for (int i = 0; i < trkpts.length; i++) {
      final trkpt = trkpts.elementAt(i);
      final latStr = trkpt.getAttribute('lat');
      final lonStr = trkpt.getAttribute('lon');
      final eleElement = trkpt.findElements('ele').firstOrNull;
      final timeElement = trkpt.findElements('time').firstOrNull;
      
      if (latStr == null || lonStr == null || eleElement == null || timeElement == null) {
        continue;
      }
      
      final lat = double.parse(latStr);
      final lon = double.parse(lonStr);
      final ele = double.parse(eleElement.innerText);
      final time = DateTime.parse(timeElement.innerText);
      
      // FIFO буфер для локаций
      // Нам нужно smoothingWindow + 1 точек, чтобы измерить разницу между i-N и i
      final historySize = smoothingWindow; 
      
      double speed = 0.0;
      double heading = 0.0;
      
      if (locations.length >= historySize && i > 0) {
        // Берем точку, которая была historySize шагов назад (или самую первую, если история еще не полная, но так как мы требуем length >= historySize, это безопасно)
        final prevLocation = locations[locations.length - historySize];
        final prevLatLng = LatLng(prevLocation.latitude, prevLocation.longitude);
        final currentLatLng = LatLng(lat, lon);
        
        final distMeters = _calculateExactDistance(prevLatLng, currentLatLng);
        final timeDiffMs = time.difference(prevLocation.timestamp).inMilliseconds;
        
        if (timeDiffMs > 0) {
          speed = (distMeters / timeDiffMs) * 1000.0;
        }
        
        heading = distance.bearing(prevLatLng, currentLatLng);
        if (heading < 0) {
          heading += 360.0;
        }
      } else if (i > 0) {
         // Для самых первых точек, пока буфер не наполнился, считаем по соседним (historySize = 1)
        final prevLocation = locations[locations.length - 1];
        final prevLatLng = LatLng(prevLocation.latitude, prevLocation.longitude);
        final currentLatLng = LatLng(lat, lon);
        
        final distMeters = _calculateExactDistance(prevLatLng, currentLatLng);
        final timeDiffMs = time.difference(prevLocation.timestamp).inMilliseconds;
        
        if (timeDiffMs > 0) {
          speed = (distMeters / timeDiffMs) * 1000.0;
        }
        
        heading = distance.bearing(prevLatLng, currentLatLng);
        if (heading < 0) {
          heading += 360.0;
        }
      }
      
      locations.add(LocationEntity(
        latitude: lat,
        longitude: lon,
        altitude: ele,
        speed: speed,
        heading: heading,
        timestamp: time,
      ));
    }
    
    return locations;
  }

  static double _calculateExactDistance(LatLng p1, LatLng p2) {
    const R = 6371000.0; // Радиус Земли в метрах
    final lat1 = p1.latitudeInRad;
    final lat2 = p2.latitudeInRad;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180.0;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.cos(lat1) * math.cos(lat2) *
              math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return R * c;
  }
}
