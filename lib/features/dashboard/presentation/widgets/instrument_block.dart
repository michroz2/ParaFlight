// Версия: 0.1.0 | Цель: Повторно используемый виджет авиационного прибора (HUD)

import 'package:flutter/material.dart';

class InstrumentBlock extends StatelessWidget {
  final String title;
  final String unit;
  final String value;
  final Color titleColor;
  final double width;
  final VoidCallback? onTap;

  const InstrumentBlock({
    super.key,
    required this.title,
    required this.unit,
    required this.value,
    this.titleColor = Colors.amber,
    this.width = 120,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xDD333333),
        border: Border.all(color: Colors.white60, width: 1.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      unit,
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
                    value,
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
} // конец класса InstrumentBlock
