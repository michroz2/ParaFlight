// Версия: 0.1.0 | Цель: Отрисовка круга ветра с радарным масштабом

import 'dart:math';
import 'package:flutter/material.dart';

class WindCirclePainter extends CustomPainter {
  final double windDirection;
  final double windSpeed;
  final double mapRotation;
  final double diameter;
  final String scaleText;
  final bool showNorthPointer;

  WindCirclePainter({
    required this.windDirection,
    required this.windSpeed,
    required this.mapRotation,
    required this.diameter,
    required this.scaleText,
    required this.showNorthPointer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = diameter / 2;

    // 1. Отрисовка пунктирного круга
    final circlePaint = Paint()
      ..color = Colors.black.withAlpha(80)
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

    // 2. Радарная шкала масштаба (влево)
    final scalePaint = Paint()
      ..color = Colors.black.withAlpha(80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Рисуем пунктир от центра влево (до круга)
    double currentX = center.dx;
    final double scaleDashWidth = 4.0;
    final double scaleDashSpace = 4.0;
    while (currentX > center.dx - radius) {
      canvas.drawLine(
        Offset(currentX, center.dy), 
        Offset(max(center.dx - radius, currentX - scaleDashWidth), center.dy), 
        scalePaint
      );
      currentX -= (scaleDashWidth + scaleDashSpace);
    }

    // Текст масштаба ближе к кругу
    final scaleSpan = TextSpan(
      text: scaleText,
      style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
    );
    final scaleTextPainter = TextPainter(
      text: scaleSpan,
      textDirection: TextDirection.ltr,
    );
    scaleTextPainter.layout();
    
    // Размещение текста: над линией, ближе к краю круга
    final scaleTextX = center.dx - radius + 4.0;
    final scaleTextY = center.dy - scaleTextPainter.height - 2.0;

    // Отрисовка полупрозрачного фона для текста
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        scaleTextX - 2, 
        scaleTextY - 1, 
        scaleTextPainter.width + 4, 
        scaleTextPainter.height + 2
      ),
      const Radius.circular(4),
    );
    final bgPaint = Paint()..color = Colors.white.withAlpha(120);
    canvas.drawRRect(bgRect, bgPaint);

    scaleTextPainter.paint(canvas, Offset(scaleTextX, scaleTextY));

    // 3. Отрисовка линии, указывающей на север (только если курс сверху)
    if (showNorthPointer) {
      final northPaint = Paint()
        ..color = Colors.red.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final northAngle = -mapRotation * pi / 180.0 - pi / 2;
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      // Поворачиваем холст так, чтобы Север всегда был "сверху" (отрицательная ось Y)
      canvas.rotate(northAngle + pi / 2);

      // Красная линия от центра до края круга
      canvas.drawLine(Offset.zero, Offset(0, -radius), northPaint);

      // Буква N
      final nSpan = const TextSpan(
        text: 'N',
        style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
      );
      final nPainter = TextPainter(text: nSpan, textDirection: TextDirection.ltr);
      nPainter.layout();

      // Размещаем N ровно под окружностью (отступ сверху = 2px)
      final bgWidth = nPainter.width + 6;
      final bgHeight = nPainter.height + 2;
      final nCenterY = -radius + bgHeight / 2 + 2; 

      final nBgRect = Rect.fromCenter(
        center: Offset(0, nCenterY),
        width: bgWidth,
        height: bgHeight,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(nBgRect, const Radius.circular(4)), Paint()..color = Colors.white.withAlpha(220));

      nPainter.paint(canvas, Offset(-nPainter.width / 2, nCenterY - nPainter.height / 2));
      canvas.restore();
    }

    // 4. Отрисовка стрелки ветра
    final screenAngle = (windDirection - mapRotation) * pi / 180.0;
    final drawAngle = screenAngle - pi / 2;

    final tipX = center.dx + radius * cos(drawAngle);
    final tipY = center.dy + radius * sin(drawAngle);

    final arrowLength = 12.0;
    final arrowWidth = 10.0;

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

    canvas.drawPath(arrowPath, Paint()..color = Colors.blueAccent);

    // 4. Отрисовка лэйбла ветра
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

    final textDist = radius + arrowLength + 16.0; 
    final textCenterX = center.dx + textDist * cos(drawAngle);
    final textCenterY = center.dy + textDist * sin(drawAngle);

    final textRect = Rect.fromCenter(
      center: Offset(textCenterX, textCenterY),
      width: textPainter.width + 6,
      height: textPainter.height + 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(textRect, const Radius.circular(6.0)),
      Paint()..color = const Color(0xCC333333),
    );

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
           oldDelegate.diameter != diameter ||
           oldDelegate.scaleText != scaleText;
  } // конец метода shouldRepaint
} // конец класса WindCirclePainter
