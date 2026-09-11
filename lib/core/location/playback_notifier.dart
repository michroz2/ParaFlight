// =============================================================================
// Файл:    playback_notifier.dart
// Проект:  ParaFlight
// Версия:  0.6.1
// Цель:    Контроллер воспроизведения симуляции
// Изменения:
//   0.6.0 - Первичная реализация
//   0.6.1 - Добавлен инкремент seekCount при init и seek
// =============================================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'location_entity.dart';
import 'playback_state.dart';

// Новое: Notifier для управления воспроизведением
class PlaybackNotifier extends Notifier<PlaybackState> {
  List<LocationEntity> _points = [];
  List<LocationEntity> get points => _points;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  PlaybackState build() {
    return PlaybackState();
  } // конец метода build

  void init(List<LocationEntity> points) {
    _points = points;
    _currentIndex = 0;
    
    if (_points.isNotEmpty) {
      final totalDuration = _points.last.timestamp.difference(_points.first.timestamp);
      state = state.copyWith(
        currentLocation: _points.first,
        totalDuration: totalDuration,
        currentDuration: Duration.zero,
        isPlaying: false,
        hasStarted: false,
        seekCount: state.seekCount + 1, // Новое: Сигнал слушателям о старте/перемотке
      );
    } // конец if
  } // конец метода init

  void togglePlay() {
    state = state.copyWith(
      isPlaying: !state.isPlaying,
      hasStarted: true,
    );
    if (state.isPlaying) {
      _playNext();
    } else {
      _timer?.cancel();
    } // конец if-else
  } // конец метода togglePlay

  void setSpeed(double speed) {
    state = state.copyWith(speedFactor: speed);
    if (state.isPlaying) {
      _timer?.cancel();
      _playNext();
    } // конец if
  } // конец метода setSpeed

  void seek(double progress) {
    if (_points.isEmpty) {
      return;
    } // конец if
    
    _timer?.cancel();
    _currentIndex = (progress * (_points.length - 1)).round();
    
    final currentDuration = _points[_currentIndex].timestamp.difference(_points.first.timestamp);
    
    state = state.copyWith(
      progress: progress,
      currentLocation: _points[_currentIndex],
      currentIndex: _currentIndex,
      currentDuration: currentDuration,
      seekCount: state.seekCount + 1, // Новое: Сигнал слушателям о перемотке
    );
    if (state.isPlaying) {
      _playNext();
    } // конец if
  } // конец метода seek

  void _playNext() {
    _timer?.cancel();
    if (!state.isPlaying || _currentIndex >= _points.length - 1) {
      return;
    } // конец if

    final currentPoint = _points[_currentIndex];
    final nextPoint = _points[_currentIndex + 1];
    
    final difference = nextPoint.timestamp.difference(currentPoint.timestamp).inMilliseconds;
    final durationMs = (difference / state.speedFactor).round();
    
    _timer = Timer(Duration(milliseconds: durationMs), () {
      _currentIndex++;
      final newProgress = _points.length > 1 ? _currentIndex / (_points.length - 1) : 1.0;
      
      final currentDuration = _points[_currentIndex].timestamp.difference(_points.first.timestamp);
      
      state = state.copyWith(
        currentLocation: _points[_currentIndex],
        progress: newProgress,
        currentIndex: _currentIndex,
        currentDuration: currentDuration,
      );
      _playNext();
    }); // конец замыкания Timer
  } // конец метода _playNext

  void reset() {
    _timer?.cancel();
    _points = [];
    _currentIndex = 0;
    state = PlaybackState();
  } // конец метода reset
} // конец класса PlaybackNotifier
