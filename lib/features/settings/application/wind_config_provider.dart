// =============================================================================
// Файл:    wind_config_provider.dart
// Проект:  ParaFlight
// Версия:  1.20.8
// Цель:    Провайдер конфигурации ветра
// Изменения:
//   0.1.0 - Первичная реализация
//   1.20.1 - Добавлен параметр enableWindArrow
//   1.20.8 - Добавлены minRoundness, maxRmseMs и minBufferPoints
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../wind/domain/wind_config.dart';

class WindConfigNotifier extends StateNotifier<WindConfig> {
  final Ref ref;

  WindConfigNotifier(this.ref) : super(const WindConfig()) {
    _loadFromPrefs();
  }

    void _loadFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    state = WindConfig(
      windowSizeSec: prefs.getDouble('windowSizeSec') ?? 240.0,
      minTurnAngleDeg: prefs.getDouble('minTurnAngleDeg') ?? 30.0,
      minAirspeedMs: prefs.getDouble('minAirspeedMs') ?? 9.0,
      maxAirspeedMs: prefs.getDouble('maxAirspeedMs') ?? 15.0,
      sampleIntervalSec: prefs.getDouble('sampleIntervalSec') ?? 0.5,
      gpxSmoothingWindow: prefs.getInt('gpxSmoothingWindow') ?? 2,
      minCogChangeDeg: prefs.getDouble('minCogChangeDeg') ?? 1.0,
      enableWindArrow: prefs.getBool('enableWindArrow') ?? true,
      enableWindOverlay: prefs.getBool('enableWindOverlay') ?? false,
      minRoundness: prefs.getDouble('minRoundness') ?? 0.5,
      maxRmseMs: prefs.getDouble('maxRmseMs') ?? 1.5,
      minBufferPoints: prefs.getInt('minBufferPoints') ?? 30,
      windEmaAlpha: prefs.getDouble('windEmaAlpha') ?? 0.2,
    );
  }

  Future<void> updateConfig({
    double? windowSizeSec,
    double? minTurnAngleDeg,
    double? minAirspeedMs,
    double? maxAirspeedMs,
    double? sampleIntervalSec,
    int? gpxSmoothingWindow,
    double? minCogChangeDeg,
    bool? enableWindArrow,
    bool? enableWindOverlay,
    double? minRoundness, // Новое
    double? maxRmseMs, // Новое
    int? minBufferPoints, // Новое
    double? windEmaAlpha, // Новое
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    
    if (windowSizeSec != null) await prefs.setDouble('windowSizeSec', windowSizeSec);
    if (minTurnAngleDeg != null) await prefs.setDouble('minTurnAngleDeg', minTurnAngleDeg);
    if (minAirspeedMs != null) await prefs.setDouble('minAirspeedMs', minAirspeedMs);
    if (maxAirspeedMs != null) await prefs.setDouble('maxAirspeedMs', maxAirspeedMs);
    if (sampleIntervalSec != null) await prefs.setDouble('sampleIntervalSec', sampleIntervalSec);
    if (gpxSmoothingWindow != null) await prefs.setInt('gpxSmoothingWindow', gpxSmoothingWindow);
    if (minCogChangeDeg != null) await prefs.setDouble('minCogChangeDeg', minCogChangeDeg);
    if (enableWindArrow != null) await prefs.setBool('enableWindArrow', enableWindArrow);
    if (enableWindOverlay != null) await prefs.setBool('enableWindOverlay', enableWindOverlay);
    if (minRoundness != null) await prefs.setDouble('minRoundness', minRoundness); // Новое
    if (maxRmseMs != null) await prefs.setDouble('maxRmseMs', maxRmseMs); // Новое
    if (minBufferPoints != null) await prefs.setInt('minBufferPoints', minBufferPoints); // Новое
    if (windEmaAlpha != null) await prefs.setDouble('windEmaAlpha', windEmaAlpha); // Новое

    state = state.copyWith(
      windowSizeSec: windowSizeSec,
      minTurnAngleDeg: minTurnAngleDeg,
      minAirspeedMs: minAirspeedMs,
      maxAirspeedMs: maxAirspeedMs,
      sampleIntervalSec: sampleIntervalSec,
      gpxSmoothingWindow: gpxSmoothingWindow,
      minCogChangeDeg: minCogChangeDeg,
      enableWindArrow: enableWindArrow,
      enableWindOverlay: enableWindOverlay,
      minRoundness: minRoundness, // Новое
      maxRmseMs: maxRmseMs, // Новое
      minBufferPoints: minBufferPoints, // Новое
      windEmaAlpha: windEmaAlpha, // Новое
    );
  }
} // конец класса WindConfigNotifier

final windConfigProvider = StateNotifierProvider<WindConfigNotifier, WindConfig>((ref) {
  return WindConfigNotifier(ref);
});
