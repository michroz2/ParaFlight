// Версия: 0.1.0 | Цель: Состояние воспроизведения симуляции

import 'location_entity.dart';

// Новое: Класс состояния воспроизведения
class PlaybackState {
  final LocationEntity? currentLocation;
  final bool isPlaying;
  final double speedFactor;
  final double progress;

  PlaybackState({
    this.currentLocation,
    this.isPlaying = true,
    this.speedFactor = 1.0,
    this.progress = 0.0,
  }); // конец конструктора

  PlaybackState copyWith({
    LocationEntity? currentLocation,
    bool? isPlaying,
    double? speedFactor,
    double? progress,
  }) {
    return PlaybackState(
      currentLocation: currentLocation ?? this.currentLocation,
      isPlaying: isPlaying ?? this.isPlaying,
      speedFactor: speedFactor ?? this.speedFactor,
      progress: progress ?? this.progress,
    );
  } // конец метода copyWith
} // конец класса PlaybackState
