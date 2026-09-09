// =============================================================================
// Файл:    instrument_block.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Повторно используемый виджет авиационного прибора (HUD)
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================

import 'package:flutter/material.dart';

class InstrumentBlock extends StatefulWidget {
  final String title;
  final String unit;
  final String value;
  final Color titleColor;
  final double width;
  final VoidCallback? onTap;
  final bool isFlashing;
  final Color flashColor;

  const InstrumentBlock({
    super.key,
    required this.title,
    required this.unit,
    required this.value,
    this.titleColor = Colors.amber,
    this.width = 120,
    this.onTap,
    this.isFlashing = false,
    this.flashColor = Colors.orange,
  });

  @override
  State<InstrumentBlock> createState() => _InstrumentBlockState();
}

class _InstrumentBlockState extends State<InstrumentBlock> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _colorAnimation = ColorTween(
      begin: const Color(0xDD333333),
      end: widget.flashColor,
    ).animate(_controller);

    if (widget.isFlashing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(InstrumentBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.flashColor != oldWidget.flashColor) {
      _colorAnimation = ColorTween(
        begin: const Color(0xDD333333),
        end: widget.flashColor,
      ).animate(_controller);
    }

    if (widget.isFlashing && !oldWidget.isFlashing) {
      _controller.repeat(reverse: true);
    } else if (!widget.isFlashing && oldWidget.isFlashing) {
      _controller.reset();
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          margin: const EdgeInsets.only(bottom: 4.0),
          decoration: BoxDecoration(
            color: widget.isFlashing ? _colorAnimation.value : const Color(0xDD333333),
            border: Border.all(color: Colors.white60, width: 1.5),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(4.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      widget.unit,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
