// =============================================================================
// Файл:    wind_pipeline.dart
// Проект:  ParaFlight
// Версия:  1.20.8
// Цель:    Конвейер вычисления ветра (буферизация и запуск)
// Изменения:
//   0.2.0 - Первичная реализация
//   1.20.2 - Улучшен расчет амбиентного ветра. Собирается Минимальный рабочий буфер. Если расчеты дают некорректные ошибки, буфер очищается.
//   1.20.3 - Проброс угла в математическое ядро
//   1.20.4 - Добавлены геттеры bufferSize и currentBufferAngle
//   1.20.5 - Перенос валидации из математического ядра в конвейер
//   1.20.8 - Использование minBufferPoints и умная защита буфера от истощения
// =============================================================================

import 'dart:math';
import '../domain/wind_config.dart';
import '../domain/wind_models.dart';
import '../domain/circle_kasa_fit.dart';

class WindPipeline {
  final WindConfig config;
  final List<WindDataPoint> _buffer = [];
  DateTime? _lastSampleTime;

  // Новое: Живые метрики буфера
  int get bufferSize => _buffer.length;

  double get currentBufferAngle {
    if (_buffer.length < 2) return 0.0;
    double maxDelta = 0.0;
    for (int i = 0; i < _buffer.length; i++) {
      for (int j = i + 1; j < _buffer.length; j++) {
        double delta = (_buffer[i].cog - _buffer[j].cog).abs();
        if (delta > 180.0) delta = 360.0 - delta;
        if (delta > maxDelta) maxDelta = delta;
      } // конец for j
    } // конец for i
    return maxDelta;
  } // конец геттера currentBufferAngle

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
    // Изменение: Умная очистка буфера с защитой от истощения
    final cutoffTime = timestamp.subtract(Duration(milliseconds: (config.windowSizeSec * 1000).toInt()));
    
    while (_buffer.length > (config.minBufferPoints + 5)) {
      if (_buffer.first.timestamp.isBefore(cutoffTime)) {
        _buffer.removeAt(0);
      } else {
        break; // Старых точек больше нет
      }
    } // конец while

// 4. ЭШЕЛОН 1 и 2: Проверка рабочего буфера (Без стирания!)
    if (_buffer.length < config.minBufferPoints) return null; // Изменение: Не накоплен минимум точек. Ждем.

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
    // Изменение: Передаем maxDelta как bufferAngle
    final result = CircleKasaFit.fit(_buffer, maxDelta);

    // 6. ЭШЕЛОН 3: Валидация физики и Умное Стирание (Smart Flush)
    if (result == null) {
      // Это происходит только если детерминант близок к нулю (идеальная прямая, что маловероятно после фильтров).
      return null;
    }

    // Новое: Проверяем физику и качество
    final bool isAirspeedValid = result.airspeed >= config.minAirspeedMs && result.airspeed <= config.maxAirspeedMs;
    final bool isRmseValid = result.rmse <= config.maxRmseMs;
    final bool isRoundnessValid = result.roundness >= config.minRoundness;

    if (isAirspeedValid && isRmseValid && isRoundnessValid) {
      return result; // Всё идеально! Отдаем свежий ветер (isValid: true по умолчанию).
    } else {
      // Новое: Окружность найдена, но данные забракованы.
      // Изменение: Аэродинамическая промывка (удаляем половину самых старых точек)
      if (_buffer.isNotEmpty) {
        final half = _buffer.length ~/ 2;
        _buffer.removeRange(0, half);
      }
      return result.copyWith(isValid: false);
    }
  }
}