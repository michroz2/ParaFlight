import 'dart:io';
void main() {
  final str = File('assets/mock_flight.gpx').readAsStringSync();
  final regex = RegExp(r'<trkpt\s+lat="([^"]+)"\s+lon="([^"]+)".*?<\/trkpt>', dotAll: true);
  final matches = regex.allMatches(str).toList();
  print(matches.length);
  if (matches.isNotEmpty) {
    final matchStr = matches[0].group(0)!;
    final timeMatch = RegExp(r'<time>([^<]+)<\/time>').firstMatch(matchStr);
    print(timeMatch?.group(1));
  }
}
