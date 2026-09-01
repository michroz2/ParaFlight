// Версия: 0.1.1 | Цель: Провайдеры локации и состояния GPX

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'location_entity.dart';
import 'gpx_parser.dart';

import '../../features/wind/domain/wind_config.dart';

// Новое: импорты для плеера
import 'playback_state.dart';
import 'playback_notifier.dart';

// Новое: Провайдер для PlaybackNotifier
final playbackProvider = NotifierProvider<PlaybackNotifier, PlaybackState>(() {
  return PlaybackNotifier();
}); // конец playbackProvider

final gpxPointsProvider = FutureProvider<List<LocationEntity>>((ref) async {
  // Загружаем файл с явным отключением кэширования
  final xmlString = await rootBundle.loadString('assets/mock_flight.gpx', cache: false);
  const config = WindConfig();
  final points = GpxParser.parse(xmlString, smoothingWindow: config.gpxSmoothingWindow);
  // Изменение: инициализируем плеер
  Future.microtask(() {
    ref.read(playbackProvider.notifier).init(points);
  }); // конец микротаска
  return points;
}); // конец gpxPointsProvider

// Изменение: удален StreamProvider
// Новое: Провайдер текущей локации из плеера
final locationProvider = Provider<LocationEntity?>((ref) {
  return ref.watch(playbackProvider).currentLocation;
}); // конец locationProvider

