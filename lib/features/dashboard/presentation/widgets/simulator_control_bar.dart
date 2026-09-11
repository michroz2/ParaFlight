// =============================================================================
// Файл:    simulator_control_bar.dart
// Проект:  ParaFlight
// Версия:  0.1.1
// Цель:    Изолированная панель управления плеером симулятора
// Изменения:
//   0.1.0 - Первичная реализация
//   0.1.1 - Кнопка Replay при окончании симуляции
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/location/location_state.dart';

class SimulatorControlBar extends ConsumerWidget {
  final bool isPreviewVisible;
  final VoidCallback onTogglePreview;

  const SimulatorControlBar({
    super.key,
    required this.isPreviewVisible,
    required this.onTogglePreview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackProvider);
    final playbackNotifier = ref.read(playbackProvider.notifier);

    return SafeArea(
      bottom: true, top: false, left: true, right: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xDD333333),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: onTogglePreview,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    Icons.gesture,
                    color: isPreviewVisible ? Colors.purpleAccent : Colors.white54,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => playbackNotifier.togglePlay(),
                child: Icon(
                  // Изменение: Показываем Replay, если трек закончен
                  playbackState.progress >= 1.0 
                      ? Icons.replay 
                      : (playbackState.isPlaying ? Icons.pause : Icons.play_arrow),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6.0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12.0,
                        ),
                      ),
                      child: Slider(
                        value: playbackState.progress,
                        activeColor: Colors.blueAccent,
                        inactiveColor: Colors.white24,
                        onChanged: (value) => playbackNotifier.seek(value),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playbackState.currentDuration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _formatDuration(playbackState.totalDuration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  double nextSpeed = playbackState.speedFactor == 1.0
                      ? 2.0
                      : playbackState.speedFactor == 2.0
                          ? 5.0
                          : playbackState.speedFactor == 5.0
                              ? 10.0
                              : playbackState.speedFactor == 10.0
                                  ? 20.0
                                  : playbackState.speedFactor == 20.0
                                      ? 60.0
                                      : 1.0;
                  playbackNotifier.setSpeed(nextSpeed);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${playbackState.speedFactor.toInt()}x',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  } // конец метода build
} // конец класса SimulatorControlBar

// Локальная функция форматирования времени (перенесена из dashboard_screen)
String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  if (duration.inHours > 0) {
    return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
  }
  return "$twoDigitMinutes:$twoDigitSeconds";
}