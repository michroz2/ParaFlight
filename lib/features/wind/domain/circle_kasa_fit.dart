// Версия: 0.2.0 | Цель: Математическое ядро фиттинга окружности (Kasa Fit)

import 'dart:math';
import 'wind_models.dart';

class CircleKasaFit {
  /// Вычисляет параметры окружности и возвращает вектор ветра и радиус.
  /// Возвращает null, если точек недостаточно, или они лежат на прямой.
  static WindCalculationResult? fit(List<WindDataPoint> points) {
    if (points.length < 3) return null;

    final n = points.length;
    double sumVx = 0;
    double sumVy = 0;

    for (final p in points) {
      sumVx += p.vx;
      sumVy += p.vy;
    }

    final meanVx = sumVx / n;
    final meanVy = sumVy / n;

    double mxx = 0;
    double myy = 0;
    double mxy = 0;
    double mxz = 0;
    double myz = 0;

    for (final p in points) {
      final xi = p.vx - meanVx;
      final yi = p.vy - meanVy;
      final zi = xi * xi + yi * yi;

      mxx += xi * xi;
      myy += yi * yi;
      mxy += xi * yi;
      mxz += xi * zi;
      myz += yi * zi;
    }

    mxx /= n;
    myy /= n;
    mxy /= n;
    mxz /= n;
    myz /= n;

    final d = (mxx * myy) - (mxy * mxy);

    // Если детерминант близок к нулю, точки лежат на прямой линии
    if (d.abs() < 1e-6) {
      return null;
    }

    final xc = ((mxz * myy) - (myz * mxy)) / (2 * d);
    final yc = ((myz * mxx) - (mxz * mxy)) / (2 * d);

    // Восстанавливаем глобальные координаты ветра (вектор куда дует ветер)
    final wx = xc + meanVx;
    final wy = yc + meanVy;

    // Скорость ветра
    final windSpeed = sqrt(wx * wx + wy * wy);

    // Воздушная скорость (радиус). meanZ = mxx + myy.
    final r = sqrt(xc * xc + yc * yc + mxx + myy);

    // Направление ветра (откуда дует)
    // Вектор Wx, Wy указывает куда дует. 
    // Поскольку X - Восток, Y - Север:
    // Азимут куда дует: atan2(Wx, Wy)
    // Разворачиваем на 180 градусов, чтобы получить "откуда дует"
    final windDestRad = atan2(wx, wy);
    double windOriginDeg = (windDestRad * 180.0 / pi + 180.0) % 360.0;
    if (windOriginDeg < 0) {
      windOriginDeg += 360.0;
    }

    // Расчет среднеквадратичной ошибки (RMSE)
    double sumSquaredError = 0.0;
    for (final p in points) {
      final xi = p.vx - meanVx;
      final yi = p.vy - meanVy;
      
      final dist = sqrt(pow(xi - xc, 2) + pow(yi - yc, 2));
      final diff = dist - r;
      sumSquaredError += diff * diff;
    }
    
    final rmse = sqrt(sumSquaredError / n);

    return WindCalculationResult(
      windSpeed: windSpeed,
      windDirection: windOriginDeg,
      airspeed: r,
      rmse: rmse,
      timestamp: points.last.timestamp,
    );
  }
}
