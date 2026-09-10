// =============================================================================
// Файл:    wind_pipeline.dart
// Проект:  ParaFlight
// Версия:  1.20.2
// Цель:    Конвейер вычисления ветра (буферизация и запуск)
// Изменения:
//   0.2.0 - Первичная реализация
//   1.20.2 - Улучшен расчет амбиентного ветра. Собирается Минимальный рабочий буфер. Если расчеты дают некорректные ошибки, буфер очищается.
// =============================================================================

import 'dart:math';
import '../domain/wind_config.dart';
import '../domain/wind_models.dart';
import '../domain/circle_kasa_fit.dart';

class WindPipeline {
  final WindConfig config;
  final List<WindDataPoint> _buffer = [];
  DateTime? _lastSampleTime;

  WindPipeline({this.config = const WindConfig()});

  void reset() {
    _buffer.clear();
    _lastSampleTime = null;
  }

  /// Добавляет новую точку геолокации и возвращает результат вычислений,
  /// если маневр валиден и результат успешен.
  WindCalculationResult? processLocation(DateTime timestamp, double speed, double heading) {
    // 0. Прореживание (Decimation)
    // Временной фильтр (анти-джиттер)
    if (_lastSampleTime != null) {
      final diff = timestamp.difference(_lastSampleTime!).inMilliseconds;
      if (diff < config.sampleIntervalSec * 1000) {
        return null; // Слишком рано
      }
    }

    // Угловой фильтр (пространственная дискретизация)
    if (_buffer.isNotEmpty) {
      final lastCog = _buffer.last.cog;
      double delta = (heading - lastCog).abs();
      if (delta > 180.0) {
        delta = 360.0 - delta;
      }
      
      if (delta < config.minCogChangeDeg) {
        return null; // Летим по прямой (курс изменился недостаточно)
      }
    }
    
    _lastSampleTime = timestamp;

    // 1. Трансформация SOG/COG в Vx, Vy (X - Восток, Y - Север)
    final headingRad = heading * pi / 180.0;
    final vx = speed * sin(headingRad);
    final vy = speed * cos(headingRad);

    final point = WindDataPoint(
      timestamp: timestamp,
      vx: vx,
      vy: vy,
      cog: heading,
    );

    // 2. Добавление в буфер
    _buffer.add(point);

    // 3. Очистка старых данных из кольцевого буфера
    final cutoffTime = timestamp.subtract(Duration(milliseconds: (config.windowSizeSec * 1000).toInt()));
    _buffer.removeWhere((p) => p.timestamp.isBefore(cutoffTime));

// 4. ЭШЕЛОН 1 и 2: Проверка рабочего буфера (Без стирания!)
    if (_buffer.length < 5) return null; // Изменение: Не накоплен минимум точек. Ждем.

    double maxDelta = 0;
    for (int i = 0; i < _buffer.length; i++) {
      for (int j = i + 1; j < _buffer.length; j++) {
        double delta = (_buffer[i].cog - _buffer[j].cog).abs();
        if (delta > 180.0) {
          delta = 360.0 - delta;
        }
        if (delta > maxDelta) {
          maxDelta = delta;
        }
      } // конец for j
    } // конец for i

    if (maxDelta < config.minTurnAngleDeg) {
      return null; // Изменение: Летим по прямой (недостаточно угла). Ждем.
    }

    // 5. Вычисление ветра через математическое ядро
    final result = CircleKasaFit.fit(_buffer, minRoundness: config.minRoundness);

    // 6. ЭШЕЛОН 3: Валидация физики и Умное Стирание (Smart Flush)
    if (result == null) {
      // Новое: Рабочий буфер собран (угол достаточен), но ядро забраковало форму (Roundness).
      // Это искажение от акселератора. Стираем яд!
      _buffer.clear();
      return null;
    }

    // Новое: Проверяем физику и качество
    final bool isAirspeedValid = result.airspeed >= config.minAirspeedMs && result.airspeed <= config.maxAirspeedMs;
    final bool isRmseValid = result.rmse <= config.maxRmseMs;

    if (isAirspeedValid && isRmseValid) {
      return result; // Всё идеально! Отдаем свежий ветер.
    } else {
      // Новое: Окружность найдена, но скорость или погрешность запредельные. Стираем яд!
      _buffer.clear();
      return null;
    }
  }
}