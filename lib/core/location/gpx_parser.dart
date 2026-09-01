import 'dart:math' as math;
import 'dart:isolate';
import 'package:latlong2/latlong.dart';
import 'location_entity.dart';

// Функция парсинга в Isolate с прогресс-баром
void parseGpxStreamingIsolate(Map<String, dynamic> args) {
  final SendPort sendPort = args['sendPort'];
  final String xmlString = args['xmlString'];
  final int smoothingWindow = args['smoothingWindow'];
  
  try {
    final trkptRegex = RegExp(r'<trkpt\s+lat="([^"]+)"\s+lon="([^"]+)".*?<\/trkpt>', dotAll: true);
    final eleRegex = RegExp(r'<ele>([^<]+)<\/ele>');
    final timeRegex = RegExp(r'<time>([^<]+)<\/time>');
    
    final matches = trkptRegex.allMatches(xmlString).toList();
    final total = matches.length;
    
    if (total == 0) {
      sendPort.send(<LocationEntity>[]);
      return;
    }

    final List<LocationEntity> locations = [];
    const R = 6371000.0; // Радиус Земли в метрах
    final historySize = math.max(1, smoothingWindow);
    
    for (int i = 0; i < total; i++) {
      final match = matches[i];
      final matchStr = match.group(0)!;
      final latStr = match.group(1);
      final lonStr = match.group(2);
      
      final eleMatch = eleRegex.firstMatch(matchStr);
      final timeMatch = timeRegex.firstMatch(matchStr);
      
      final eleStr = eleMatch?.group(1);
      final timeStr = timeMatch?.group(1);
      
      if (latStr == null || lonStr == null || timeStr == null) continue;
      
      final lat = double.parse(latStr);
      final lon = double.parse(lonStr);
      final ele = eleStr != null ? double.parse(eleStr) : 0.0;
      final time = DateTime.parse(timeStr);
      
      double speed = 0.0;
      double heading = 0.0;
      
      if (locations.length >= historySize) {
        final prevLocation = locations[locations.length - historySize];
        final distMeters = _calculateFastDistance(prevLocation.latitude, prevLocation.longitude, lat, lon, R);
        final timeDiffMs = time.difference(prevLocation.timestamp).inMilliseconds;
        
        if (timeDiffMs > 0) speed = (distMeters / timeDiffMs) * 1000.0;
        heading = _calculateBearing(prevLocation.latitude, prevLocation.longitude, lat, lon);
      } else if (locations.isNotEmpty) {
        final prevLocation = locations.last;
        final distMeters = _calculateFastDistance(prevLocation.latitude, prevLocation.longitude, lat, lon, R);
        final timeDiffMs = time.difference(prevLocation.timestamp).inMilliseconds;
        
        if (timeDiffMs > 0) speed = (distMeters / timeDiffMs) * 1000.0;
        heading = _calculateBearing(prevLocation.latitude, prevLocation.longitude, lat, lon);
      }
      
      locations.add(LocationEntity(
        latitude: lat,
        longitude: lon,
        altitude: ele,
        speed: speed,
        heading: heading,
        timestamp: time,
      ));
      
      // Отправляем прогресс каждые 200 точек
      if (i % 200 == 0) {
        sendPort.send(i / total);
      }
    }
    
    sendPort.send(locations);
  } catch (e, stack) {
    sendPort.send(e.toString());
  }
}

double _calculateFastDistance(double lat1, double lon1, double lat2, double lon2, double R) {
  final dLat = (lat2 - lat1) * math.pi / 180.0;
  final dLon = (lon2 - lon1) * math.pi / 180.0;
  final rLat1 = lat1 * math.pi / 180.0;
  final rLat2 = lat2 * math.pi / 180.0;

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
            math.cos(rLat1) * math.cos(rLat2) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return R * c;
}

double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
  final dLon = (lon2 - lon1) * math.pi / 180.0;
  final rLat1 = lat1 * math.pi / 180.0;
  final rLat2 = lat2 * math.pi / 180.0;
  
  final y = math.sin(dLon) * math.cos(rLat2);
  final x = math.cos(rLat1) * math.sin(rLat2) -
            math.sin(rLat1) * math.cos(rLat2) * math.cos(dLon);
  var brng = math.atan2(y, x) * 180.0 / math.pi;
  return (brng + 360.0) % 360.0;
}
