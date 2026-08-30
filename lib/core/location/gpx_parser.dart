import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import 'location_entity.dart';

class GpxParser {
  static List<LocationEntity> parse(String xmlString) {
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
      
      double speed = 0.0;
      double heading = 0.0;
      
      if (i > 0) {
        final prevLocation = locations[i - 1];
        final prevLatLng = LatLng(prevLocation.latitude, prevLocation.longitude);
        final currentLatLng = LatLng(lat, lon);
        
        final distMeters = distance(prevLatLng, currentLatLng);
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
}
