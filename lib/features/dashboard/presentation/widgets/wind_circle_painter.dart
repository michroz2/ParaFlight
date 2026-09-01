// Версия: 0.1.0 | Цель: Отрисовка круга ветра, стрелки и значения (CustomPainter)

import 'dart:math';
import 'package:flutter/material.dart';

class WindCirclePainter extends CustomPainter {
  final double windDirection;
  final double windSpeed;
  final double mapRotation;
  final double diameter;

  WindCirclePainter({
    required this.windDirection,
    required this.windSpeed,
    required this.mapRotation,
    required this.diameter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = diameter / 2;

    // 1. Отрисовка пунктирного круга (еле видного)
    final circlePaint = Paint()
      ..color = Colors.black.withAlpha(80) // Темно-серый полупрозрачный
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final double dashWidth = 8.0;
    final double dashSpace = 8.0;
    final double circumference = 2 * pi * radius;
    final int dashCount = (circumference / (dashWidth + dashSpace)).floor();
    final double sweepAngle = dashWidth / radius;
    final double spaceAngle = dashSpace / radius;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * (sweepAngle + spaceAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        circlePaint,
      );
    } // конец for

    // 2. Отрисовка стрелки (указывает ОТКУДА дует ветер, направлена в центр)
    // Ветер дует из windDirection. Угол 0 - это Север (вверх, -PI/2 на Canvas).
    final screenAngle = (windDirection - mapRotation) * pi / 180.0;
    final drawAngle = screenAngle - pi / 2;

    // Носик стрелки касается круга снаружи
    final tipX = center.dx + radius * cos(drawAngle);
    final tipY = center.dy + radius * sin(drawAngle);

    final arrowLength = 12.0;
    final arrowWidth = 10.0;

    // Задняя часть стрелки
    final backX = center.dx + (radius + arrowLength) * cos(drawAngle);
    final backY = center.dy + (radius + arrowLength) * sin(drawAngle);

    final perpAngle = drawAngle + pi / 2;
    final p1X = backX + (arrowWidth / 2) * cos(perpAngle);
    final p1Y = backY + (arrowWidth / 2) * sin(perpAngle);
    final p2X = backX - (arrowWidth / 2) * cos(perpAngle);
    final p2Y = backY - (arrowWidth / 2) * sin(perpAngle);

    final arrowPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(p1X, p1Y)
      ..lineTo(p2X, p2Y)
      ..close();

    canvas.drawPath(arrowPath, Paint()..color = Colors.blueAccent); // Цвет стрелки ветра

    // 3. Отрисовка лэйбла (значение ветра в м/с)
    final textStr = windSpeed.toStringAsFixed(1);
    final textSpan = TextSpan(
      text: textStr,
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Центр лэйбла отодвинут от задней части стрелки
    final textDist = radius + arrowLength + 16.0; 
    final textCenterX = center.dx + textDist * cos(drawAngle);
    final textCenterY = center.dy + textDist * sin(drawAngle);

    final textRect = Rect.fromCenter(
      center: Offset(textCenterX, textCenterY),
      width: textPainter.width + 6, // Изменение: уменьшили поля в 2 раза (было 12)
      height: textPainter.height + 4, // Изменение: уменьшили поля в 2 раза (было 8)
    );

    // Темно-серый фон лэйбла
    canvas.drawRRect(
      RRect.fromRectAndRadius(textRect, const Radius.circular(6.0)),
      Paint()..color = const Color(0xCC333333),
    );

    // Отрисовка текста
    textPainter.paint(
      canvas,
      Offset(textCenterX - textPainter.width / 2, textCenterY - textPainter.height / 2),
    );
  } // конец метода paint

  @override
  bool shouldRepaint(covariant WindCirclePainter oldDelegate) {
    return oldDelegate.windDirection != windDirection ||
           oldDelegate.windSpeed != windSpeed ||
           oldDelegate.mapRotation != mapRotation ||
           oldDelegate.diameter != diameter;
  } // конец метода shouldRepaint
} // конец класса WindCirclePainter
