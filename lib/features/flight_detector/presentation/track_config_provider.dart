// =============================================================================
// Файл:    track_config_provider.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Провайдер конфигурации трека
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../domain/track_config.dart';

class TrackConfigNotifier extends StateNotifier<TrackConfig> {
  final Ref ref;

  TrackConfigNotifier(this.ref) : super(const TrackConfig()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final prefs = ref.read(sharedPreferencesProvider);
    state = TrackConfig(
      enableAutoTakeoff: prefs.getBool('enableAutoTakeoff') ?? true,
      enableMidAirStart: prefs.getBool('enableMidAirStart') ?? true,
      enableAutoLanding: prefs.getBool('enableAutoLanding') ?? true,
      enableCfvWindFail: prefs.getBool('enableCfvWindFail') ?? false,
      enableCfvIntersection: prefs.getBool('enableCfvIntersection') ?? false,
      enableCfvHighway: prefs.getBool('enableCfvHighway') ?? false,
      enableDebugMarkers: prefs.getBool('enableDebugMarkers') ?? false,
      takeoffWaitTimeSec: prefs.getInt('takeoffWaitTimeSec') ?? 5,
      takeoffFlightTimeSec: prefs.getInt('takeoffFlightTimeSec') ?? 15,
      landingConfirmTimeSec: prefs.getInt('landingConfirmTimeSec') ?? 10,
      minFlightSpeedMs: prefs.getDouble('minFlightSpeedMs') ?? 4.16,
      maxWalkSpeedMs: prefs.getDouble('maxWalkSpeedMs') ?? 1.38,
      cfvWindFailTimeoutSec: prefs.getInt('cfvWindFailTimeoutSec') ?? 180,
      cfvTurnWindowSec: prefs.getInt('cfvTurnWindowSec') ?? 5,
      gpsRecordIntervalSec: prefs.getDouble('gpsRecordIntervalSec') ?? 0.5,
      gpsCleanupExtraSec: prefs.getInt('gpsCleanupExtraSec') ?? 30,
    );
  }

  Future<void> updateConfig({
    bool? enableAutoTakeoff,
    bool? enableMidAirStart,
    bool? enableAutoLanding,
    bool? enableCfvWindFail,
    bool? enableCfvIntersection,
    bool? enableCfvHighway,
    bool? enableDebugMarkers,
    int? takeoffWaitTimeSec,
    int? takeoffFlightTimeSec,
    int? landingConfirmTimeSec,
    double? minFlightSpeedMs,
    double? maxWalkSpeedMs,
    int? cfvWindFailTimeoutSec,
    int? cfvTurnWindowSec,
    double? gpsRecordIntervalSec,
    int? gpsCleanupExtraSec,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);

    if (enableAutoTakeoff != null) await prefs.setBool('enableAutoTakeoff', enableAutoTakeoff);
    if (enableMidAirStart != null) await prefs.setBool('enableMidAirStart', enableMidAirStart);
    if (enableAutoLanding != null) await prefs.setBool('enableAutoLanding', enableAutoLanding);
    if (enableCfvWindFail != null) await prefs.setBool('enableCfvWindFail', enableCfvWindFail);
    if (enableCfvIntersection != null) await prefs.setBool('enableCfvIntersection', enableCfvIntersection);
    if (enableCfvHighway != null) await prefs.setBool('enableCfvHighway', enableCfvHighway);
    if (enableDebugMarkers != null) await prefs.setBool('enableDebugMarkers', enableDebugMarkers);
    if (takeoffWaitTimeSec != null) {
      await prefs.setInt('takeoffWaitTimeSec', takeoffWaitTimeSec);
    }
    if (takeoffFlightTimeSec != null) {
      await prefs.setInt('takeoffFlightTimeSec', takeoffFlightTimeSec);
    }
    if (landingConfirmTimeSec != null) {
      await prefs.setInt('landingConfirmTimeSec', landingConfirmTimeSec);
    }
    if (minFlightSpeedMs != null) {
      await prefs.setDouble('minFlightSpeedMs', minFlightSpeedMs);
    }
    if (maxWalkSpeedMs != null) {
      await prefs.setDouble('maxWalkSpeedMs', maxWalkSpeedMs);
    }
    if (cfvWindFailTimeoutSec != null) {
      await prefs.setInt('cfvWindFailTimeoutSec', cfvWindFailTimeoutSec);
    }
    if (cfvTurnWindowSec != null) {
      await prefs.setInt('cfvTurnWindowSec', cfvTurnWindowSec);
    }
    if (gpsRecordIntervalSec != null) {
      await prefs.setDouble('gpsRecordIntervalSec', gpsRecordIntervalSec);
    }
    if (gpsCleanupExtraSec != null) {
      await prefs.setInt('gpsCleanupExtraSec', gpsCleanupExtraSec);
    }

    state = state.copyWith(
      enableAutoTakeoff: enableAutoTakeoff,
      enableMidAirStart: enableMidAirStart,
      enableAutoLanding: enableAutoLanding,
      enableCfvWindFail: enableCfvWindFail,
      enableCfvIntersection: enableCfvIntersection,
      enableCfvHighway: enableCfvHighway,
      enableDebugMarkers: enableDebugMarkers,
      takeoffWaitTimeSec: takeoffWaitTimeSec,
      takeoffFlightTimeSec: takeoffFlightTimeSec,
      landingConfirmTimeSec: landingConfirmTimeSec,
      minFlightSpeedMs: minFlightSpeedMs,
      maxWalkSpeedMs: maxWalkSpeedMs,
      cfvWindFailTimeoutSec: cfvWindFailTimeoutSec,
      cfvTurnWindowSec: cfvTurnWindowSec,
      gpsRecordIntervalSec: gpsRecordIntervalSec,
      gpsCleanupExtraSec: gpsCleanupExtraSec,
    );
  }
} // конец класса TrackConfigNotifier

final trackConfigProvider =
    StateNotifierProvider<TrackConfigNotifier, TrackConfig>((ref) {
      return TrackConfigNotifier(ref);
    });
