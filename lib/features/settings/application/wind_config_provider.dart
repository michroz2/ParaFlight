// =============================================================================
// Файл:    wind_config_provider.dart
// Проект:  ParaFlight
// Версия:  1.20.1
// Цель:    Провайдер конфигурации ветра
// Изменения:
//   0.1.0 - Первичная реализация
//   1.20.1 - Добавлен параметр enableWindArrow
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
      windowSizeSec: prefs.getDouble('windowSizeSec') ?? 120.0,
      minTurnAngleDeg: prefs.getDouble('minTurnAngleDeg') ?? 30.0,
      minAirspeedMs: prefs.getDouble('minAirspeedMs') ?? 5.55,
      maxAirspeedMs: prefs.getDouble('maxAirspeedMs') ?? 19.44,
      sampleIntervalSec: prefs.getDouble('sampleIntervalSec') ?? 0.5,
      gpxSmoothingWindow: prefs.getInt('gpxSmoothingWindow') ?? 2,
      minCogChangeDeg: prefs.getDouble('minCogChangeDeg') ?? 1.0,
      enableWindArrow: prefs.getBool('enableWindArrow') ?? true, // Новое
      enableWindOverlay: prefs.getBool('enableWindOverlay') ?? false,
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
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    
    if (windowSizeSec != null) await prefs.setDouble('windowSizeSec', windowSizeSec);
    if (minTurnAngleDeg != null) await prefs.setDouble('minTurnAngleDeg', minTurnAngleDeg);
    if (minAirspeedMs != null) await prefs.setDouble('minAirspeedMs', minAirspeedMs);
    if (maxAirspeedMs != null) await prefs.setDouble('maxAirspeedMs', maxAirspeedMs);
    if (sampleIntervalSec != null) await prefs.setDouble('sampleIntervalSec', sampleIntervalSec);
    if (gpxSmoothingWindow != null) await prefs.setInt('gpxSmoothingWindow', gpxSmoothingWindow);
    if (minCogChangeDeg != null) await prefs.setDouble('minCogChangeDeg', minCogChangeDeg);
    if (enableWindArrow != null) await prefs.setBool('enableWindArrow', enableWindArrow); // Новое
    if (enableWindOverlay != null) await prefs.setBool('enableWindOverlay', enableWindOverlay);

    state = state.copyWith(
      windowSizeSec: windowSizeSec,
      minTurnAngleDeg: minTurnAngleDeg,
      minAirspeedMs: minAirspeedMs,
      maxAirspeedMs: maxAirspeedMs,
      sampleIntervalSec: sampleIntervalSec,
      gpxSmoothingWindow: gpxSmoothingWindow,
      minCogChangeDeg: minCogChangeDeg,
      enableWindArrow: enableWindArrow, // Новое
      enableWindOverlay: enableWindOverlay,
    );
  }
} // конец класса WindConfigNotifier

final windConfigProvider = StateNotifierProvider<WindConfigNotifier, WindConfig>((ref) {
  return WindConfigNotifier(ref);
});
