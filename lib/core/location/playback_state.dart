// Версия: 0.1.1 | Цель: Состояние воспроизведения симуляции

import 'location_entity.dart';

// Новое: Класс состояния воспроизведения
class PlaybackState {
  final LocationEntity? currentLocation;
  final bool isPlaying;
  final double speedFactor;
  final double progress;
  // Новое: Индекс текущей точки для обрезки пути
  final int currentIndex;

  PlaybackState({
    this.currentLocation,
    this.isPlaying = true,
    this.speedFactor = 1.0,
    this.progress = 0.0,
    this.currentIndex = 0,
  }); // конец конструктора

  PlaybackState copyWith({
    LocationEntity? currentLocation,
    bool? isPlaying,
    double? speedFactor,
    double? progress,
    int? currentIndex,
  }) {
    return PlaybackState(
      currentLocation: currentLocation ?? this.currentLocation,
      isPlaying: isPlaying ?? this.isPlaying,
      speedFactor: speedFactor ?? this.speedFactor,
      progress: progress ?? this.progress,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  } // конец метода copyWith
} // конец класса PlaybackState
