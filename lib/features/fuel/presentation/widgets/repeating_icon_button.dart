import 'dart:async';
import 'package:flutter/material.dart';

/// Виджет кнопки, поддерживающий единичные нажатия и непрерывное удержание (Continuous Press).
/// Отлично подходит для использования в перчатках (Glove-Friendly).
class RepeatingIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double iconSize;

  const RepeatingIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconSize = 48.0,
  });

  @override
  State<RepeatingIconButton> createState() => _RepeatingIconButtonState();
}

class _RepeatingIconButtonState extends State<RepeatingIconButton> {
  Timer? _timer;
  int _tickCount = 0;
  bool _isPressed = false;

  // Настройки таймингов (можно подкрутить позже)
  final int _initialDelayMs = 500; // Пауза для первых тиков (медленная прокрутка)
  final int _fastDelayMs = 100;    // Пауза после ускорения (быстрая прокрутка)
  final int _ticksToAccelerate = 4; // Количество тиков до ускорения (2 секунды при 500мс)

  void _startTimer() {
    _tickCount = 0;
    _timer = Timer.periodic(Duration(milliseconds: _initialDelayMs), _onTick);
  }

  void _onTick(Timer timer) {
    widget.onTap();
    _tickCount++;

    // Переключение на быстрый режим после заданного числа тиков
    if (_tickCount == _ticksToAccelerate) {
      _timer?.cancel();
      _timer = Timer.periodic(Duration(milliseconds: _fastDelayMs), _onTick);
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
      },
      onLongPressStart: (_) {
        setState(() => _isPressed = true);
        _startTimer();
      },
      onLongPressEnd: (_) {
        setState(() => _isPressed = false);
        _stopTimer();
      },
      onLongPressCancel: () {
        setState(() => _isPressed = false);
        _stopTimer();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _isPressed ? Colors.grey.withAlpha(50) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
