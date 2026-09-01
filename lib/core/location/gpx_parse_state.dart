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
