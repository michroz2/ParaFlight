// =============================================================================
// Файл:    playback_state.dart
// Проект:  ParaFlight
// Версия:  0.1.1
// Цель:    Состояние воспроизведения симуляции
// Изменения:
//   0.1.1 - Первичная реализация
// =============================================================================

import 'location_entity.dart';

// Новое: Класс состояния воспроизведения
class PlaybackState {
  final LocationEntity? currentLocation;
  final bool isPlaying;
  final bool hasStarted;
  final double speedFactor;
  final double progress;
  // Новое: Индекс текущей точки для обрезки пути
  final int currentIndex;
  // Новое: Временные метки полета
  final Duration currentDuration;
  final Duration totalDuration;

  PlaybackState({
    this.currentLocation,
    this.isPlaying = false,
    this.hasStarted = false,
    this.speedFactor = 1.0,
    this.progress = 0.0,
    this.currentIndex = 0,
    this.currentDuration = Duration.zero,
    this.totalDuration = Duration.zero,
  }); // конец конструктора

  PlaybackState copyWith({
    LocationEntity? currentLocation,
    bool? isPlaying,
    bool? hasStarted,
    double? speedFactor,
    double? progress,
    int? currentIndex,
    Duration? currentDuration,
    Duration? totalDuration,
  }) {
    return PlaybackState(
      currentLocation: currentLocation ?? this.currentLocation,
      isPlaying: isPlaying ?? this.isPlaying,
      hasStarted: hasStarted ?? this.hasStarted,
      speedFactor: speedFactor ?? this.speedFactor,
      progress: progress ?? this.progress,
      currentIndex: currentIndex ?? this.currentIndex,
      currentDuration: currentDuration ?? this.currentDuration,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  } // конец метода copyWith
} // конец класса PlaybackState
