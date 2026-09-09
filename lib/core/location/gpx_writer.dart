// =============================================================================
// Файл:    gpx_writer.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Запись трека полета в GPX-файл через LocalStorageService
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================
import 'dart:io';
import 'package:path/path.dart' as p;
import 'location_entity.dart';
import '../storage/local_storage_service.dart'; // Новое: Импорт сервиса локального хранилища
import '../../features/flight_detector/domain/flight_state.dart';

class GpxWriter {
  // Изменение: Убран метод _getTracksDirectory, теперь используем LocalStorageService

  static String _formatDate(DateTime time) {
    return "${time.year.toString().padLeft(4, '0')}${time.month.toString().padLeft(2, '0')}${time.day.toString().padLeft(2, '0')}-"
        "${time.hour.toString().padLeft(2, '0')}${time.minute.toString().padLeft(2, '0')}";
  }

  static String _generateGpxString(
    List<LocationEntity> points,
    String trackName,
  ) {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln(
      '<gpx version="1.1" creator="ParaFlight"\n'
      '  xmlns="http://www.topografix.com/GPX/1/1"\n'
      '  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n'
      '  xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">',
    );
    sb.writeln('  <trk>');
    sb.writeln('    <name>$trackName</name>');
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
    required LocalStorageService storageService, // Новое: Инжектируем сервис
  }) async {
    if (rawPoints.isEmpty) return [];

    if (flights.isEmpty) {
      final endTime = rawPoints.last.timestamp;
      final trackName = 'PF${_formatDate(endTime)}';
      final fileName = '$trackName.gpx';
      
      final content = _generateGpxString(rawPoints, trackName);
      final savedPath = await storageService.saveTrack(fileName, content); // Изменение: делегирование сервису
      return [savedPath];
    }

    if (!cleanUpExtra && !splitFlights) {
      final lastFlight = flights.last;
      final endTime = lastFlight.finish?.timestamp ?? rawPoints.last.timestamp;
      final trackName = 'PF${_formatDate(endTime)}';
      final fileName = '$trackName.gpx';
      
      final content = _generateGpxString(rawPoints, trackName);
      final savedPath = await storageService.saveTrack(fileName, content); // Изменение: делегирование сервису
      return [savedPath];
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

      String trackName = 'PF${_formatDate(endTime)}';
      String fileName = '$trackName.gpx';
      
      int copyIdx = 1;
      // Изменение: проверка через сервис
      while (await storageService.fileExists(fileName)) {
        trackName = 'PF${_formatDate(endTime)}_$copyIdx';
        fileName = '$trackName.gpx';
        copyIdx++;
      }

      final content = _generateGpxString(segmentPoints, trackName);
      final savedPath = await storageService.saveTrack(fileName, content); // Изменение: делегирование сервису
      savedFiles.add(savedPath);
    }

    return savedFiles;
  }
}
