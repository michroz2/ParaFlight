import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:paraflight/features/wind/domain/circle_kasa_fit.dart';
import 'package:paraflight/features/wind/domain/wind_models.dart';

void main() {
  group('CircleKasaFit', () {
    test('Correctly calculates wind vector and airspeed from a circle', () {
      // Имитируем полет по кругу.
      // Допустим, собственная скорость (airspeed) = 15 м/с
      // Ветер дует строго на Север (Wx = 0, Wy = 5). Скорость ветра = 5 м/с.
      // Значит, ветер дует ОТ Юга (180 градусов).
      
      final airspeed = 15.0;
      final windX = 0.0;
      final windY = 5.0; // дует на Север
      
      final points = <WindDataPoint>[];
      final now = DateTime.now();
      
      for (int i = 0; i < 360; i += 10) {
        final angleRad = i * pi / 180.0;
        // Генерируем точки окружности
        final vx = airspeed * cos(angleRad) + windX;
        final vy = airspeed * sin(angleRad) + windY;
        
        points.add(WindDataPoint(
          timestamp: now.add(Duration(seconds: i)),
          vx: vx,
          vy: vy,
          cog: atan2(vx, vy) * 180 / pi, // COG не влияет на мат. ядро, но нужен для полноты
        ));
      }

      final result = CircleKasaFit.fit(points);
      
      expect(result, isNotNull);
      expect(result!.windSpeed, closeTo(5.0, 0.01));
      expect(result.airspeed, closeTo(15.0, 0.01));
      
      // Идеальная окружность, ошибка должна быть нулевой
      expect(result.rmse, closeTo(0.0, 0.01));
      
      // Направление: дует на Север (0 азимут). Значит, дует ОТ Юга (180 градусов).
      expect(result.windDirection, closeTo(180.0, 0.01));
    });

    test('Returns null for a straight line', () {
      final points = <WindDataPoint>[];
      final now = DateTime.now();
      
      // Прямолинейный полет, Vx и Vy постоянны
      for (int i = 0; i < 10; i++) {
        points.add(WindDataPoint(
          timestamp: now.add(Duration(seconds: i)),
          vx: 10.0,
          vy: 10.0,
          cog: 45.0,
        ));
      }

      final result = CircleKasaFit.fit(points);
      expect(result, isNull);
    });
  });
}
