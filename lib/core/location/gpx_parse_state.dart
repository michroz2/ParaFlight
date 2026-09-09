// =============================================================================
// Файл:    gpx_parse_state.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Модель состояния процесса парсинга GPX-файла
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================
import 'location_entity.dart';

class GpxParseState {
  final double progress;
  final List<LocationEntity>? points;
  final bool isDone;
  final String? error;

  const GpxParseState({
    required this.progress,
    this.points,
    this.isDone = false,
    this.error,
  });
}
