import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'location_entity.dart';
import '../../features/flight_detector/domain/flight_state.dart';

class GpxWriter {
  static Future<Directory> _getTracksDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'tracks'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _formatDate(DateTime time) {
    return "${time.year.toString().padLeft(4, '0')}${time.month.toString().padLeft(2, '0')}${time.day.toString().padLeft(2, '0')}-"
        "${time.hour.toString().padLeft(2, '0')}${time.minute.toString().padLeft(2, '0')}";
  }

  static String _generateGpxString(List<LocationEntity> points) {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln('<gpx version="1.1" creator="ParaFlight">');
    sb.writeln('  <trk>');
    sb.writeln('    <trkseg>');
    for (final point in points) {
      sb.writeln(
        '      <trkpt lat="${point.latitude}" lon="${point.longitude}">',
      );
      sb.writeln('        <ele>${point.altitude}</ele>');
      sb.writeln(
        '        <time>${point.timestamp.toUtc().toIso8601String()}</time>',
      );
      sb.writeln('      </trkpt>');
    }
    sb.writeln('    </trkseg>');
    sb.writeln('  </trk>');
    sb.writeln('</gpx>');
    return sb.toString();
  }

  static Future<List<String>> saveTrack({
    required List<LocationEntity> rawPoints,
    required List<FlightRecord> flights,
    required bool cleanUpExtra,
    required bool splitFlights,
    required int cleanupExtraSec,
  }) async {
    if (rawPoints.isEmpty) return [];

    final dir = await _getTracksDirectory();

    if (flights.isEmpty) {
      final endTime = rawPoints.last.timestamp;
      final fileName = 'PF${_formatDate(endTime)}.gpx';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsString(_generateGpxString(rawPoints));
      return [file.path];
    }

    if (!cleanUpExtra && !splitFlights) {
      final lastFlight = flights.last;
      final endTime = lastFlight.finish?.timestamp ?? rawPoints.last.timestamp;
      final fileName = 'PF${_formatDate(endTime)}.gpx';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsString(_generateGpxString(rawPoints));
      return [file.path];
    }

    List<String> savedFiles = [];

    for (int i = 0; i < flights.length; i++) {
      final flight = flights[i];

      int flightStartIndex = rawPoints.indexWhere(
        (p) => p.timestamp == flight.start.timestamp,
      );
      int flightFinishIndex = flight.finish != null
          ? rawPoints.indexWhere((p) => p.timestamp == flight.finish!.timestamp)
          : rawPoints.length - 1;

      if (flightStartIndex == -1) flightStartIndex = 0;
      if (flightFinishIndex == -1 || flightFinishIndex < flightStartIndex)
        flightFinishIndex = rawPoints.length - 1;

      int segmentStartIndex = 0;
      int segmentFinishIndex = rawPoints.length - 1;

      if (cleanUpExtra) {
        final desiredStartTime = rawPoints[flightStartIndex].timestamp.subtract(
          Duration(seconds: cleanupExtraSec),
        );
        final desiredFinishTime = rawPoints[flightFinishIndex].timestamp.add(
          Duration(seconds: cleanupExtraSec),
        );

        final prevFlightFinishTime = i > 0
            ? (flights[i - 1].finish?.timestamp ?? rawPoints.first.timestamp)
            : rawPoints.first.timestamp;

        final nextFlightStartTime = i < flights.length - 1
            ? flights[i + 1].start.timestamp
            : rawPoints.last.timestamp;

        final actualStartTime = desiredStartTime.isBefore(prevFlightFinishTime)
            ? prevFlightFinishTime
            : desiredStartTime;
        final actualFinishTime = desiredFinishTime.isAfter(nextFlightStartTime)
            ? nextFlightStartTime
            : desiredFinishTime;

        segmentStartIndex = rawPoints.lastIndexWhere(
          (p) =>
              p.timestamp.isBefore(actualStartTime) ||
              p.timestamp.isAtSameMomentAs(actualStartTime),
          flightStartIndex,
        );
        if (segmentStartIndex == -1) segmentStartIndex = 0;

        segmentFinishIndex = rawPoints.indexWhere(
          (p) =>
              p.timestamp.isAfter(actualFinishTime) ||
              p.timestamp.isAtSameMomentAs(actualFinishTime),
          flightFinishIndex,
        );
        if (segmentFinishIndex == -1) segmentFinishIndex = rawPoints.length - 1;
      } else {
        if (i == 0) {
          segmentStartIndex = 0;
        } else {
          final prevFinishTime =
              flights[i - 1].finish?.timestamp ?? rawPoints.first.timestamp;
          final currentStartTime = flight.start.timestamp;
          final midTimeMs =
              prevFinishTime.millisecondsSinceEpoch +
              (currentStartTime.millisecondsSinceEpoch -
                      prevFinishTime.millisecondsSinceEpoch) ~/
                  2;
          final midTime = DateTime.fromMillisecondsSinceEpoch(midTimeMs);

          segmentStartIndex = rawPoints.indexWhere(
            (p) =>
                p.timestamp.isAfter(midTime) ||
                p.timestamp.isAtSameMomentAs(midTime),
          );
          if (segmentStartIndex == -1) segmentStartIndex = flightStartIndex;
        }

        if (i == flights.length - 1) {
          segmentFinishIndex = rawPoints.length - 1;
        } else {
          final currentFinishTime =
              flight.finish?.timestamp ?? rawPoints.last.timestamp;
          final nextStartTime = flights[i + 1].start.timestamp;
          final midTimeMs =
              currentFinishTime.millisecondsSinceEpoch +
              (nextStartTime.millisecondsSinceEpoch -
                      currentFinishTime.millisecondsSinceEpoch) ~/
                  2;
          final midTime = DateTime.fromMillisecondsSinceEpoch(midTimeMs);

          segmentFinishIndex = rawPoints.lastIndexWhere(
            (p) =>
                p.timestamp.isBefore(midTime) ||
                p.timestamp.isAtSameMomentAs(midTime),
          );
          if (segmentFinishIndex == -1) segmentFinishIndex = flightFinishIndex;
        }
      }

      final segmentPoints = rawPoints.sublist(
        segmentStartIndex,
        segmentFinishIndex + 1,
      );

      final endTime = flight.finish?.timestamp ?? segmentPoints.last.timestamp;

      String fileName = 'PF${_formatDate(endTime)}.gpx';
      File file = File(p.join(dir.path, fileName));
      int copyIdx = 1;
      while (await file.exists()) {
        fileName = 'PF${_formatDate(endTime)}_$copyIdx.gpx';
        file = File(p.join(dir.path, fileName));
        copyIdx++;
      }

      await file.writeAsString(_generateGpxString(segmentPoints));
      savedFiles.add(file.path);
    }

    return savedFiles;
  }
}
