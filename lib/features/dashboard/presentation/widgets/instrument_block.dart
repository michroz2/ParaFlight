// Версия: 0.1.0 | Цель: Повторно используемый виджет авиационного прибора (HUD)

import 'package:flutter/material.dart';

class InstrumentBlock extends StatelessWidget {
  final String title;
  final String unit;
  final String value;
  final Color titleColor;
  final double width;

  const InstrumentBlock({
    super.key,
    required this.title,
    required this.unit,
    required this.value,
    this.titleColor = Colors.amber,
    this.width = 120, // Изменение: немного увеличили ширину для надежности
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 4.0),
      // Изменение: поля внутри блока уменьшены в 2 раза (было 6 и 4)
      padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: const Color(0xDD333333),
        border: Border.all(color: Colors.white60, width: 1.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
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
          ), // конец Row
          // Изменение: Убрали SizedBox(height: 2), чтобы максимально сжать блок по вертикали
          // Изменение: FittedBox не даст тексту перенестись на новую строку
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
                height: 1.0, // Изменение: уменьшена высота строки с 1.1 до 1.0
              ),
            ),
          ), // конец FittedBox
        ],
      ), // конец Column
    ); // конец Container
  } // конец метода build
} // конец класса InstrumentBlock
