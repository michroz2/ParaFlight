// Версия: 0.1.0 | Цель: Провайдер конфигурации трека

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
      takeoffWaitTimeSec: prefs.getInt('takeoffWaitTimeSec') ?? 5,
      takeoffFlightTimeSec: prefs.getInt('takeoffFlightTimeSec') ?? 15,
      landingConfirmTimeSec: prefs.getInt('landingConfirmTimeSec') ?? 10,
      minFlightSpeedMs: prefs.getDouble('minFlightSpeedMs') ?? 4.16,
      maxWalkSpeedMs: prefs.getDouble('maxWalkSpeedMs') ?? 1.38,
    );
  }

  Future<void> updateConfig({
    int? takeoffWaitTimeSec,
    int? takeoffFlightTimeSec,
    int? landingConfirmTimeSec,
    double? minFlightSpeedMs,
    double? maxWalkSpeedMs,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    
    if (takeoffWaitTimeSec != null) await prefs.setInt('takeoffWaitTimeSec', takeoffWaitTimeSec);
    if (takeoffFlightTimeSec != null) await prefs.setInt('takeoffFlightTimeSec', takeoffFlightTimeSec);
    if (landingConfirmTimeSec != null) await prefs.setInt('landingConfirmTimeSec', landingConfirmTimeSec);
    if (minFlightSpeedMs != null) await prefs.setDouble('minFlightSpeedMs', minFlightSpeedMs);
    if (maxWalkSpeedMs != null) await prefs.setDouble('maxWalkSpeedMs', maxWalkSpeedMs);

    state = state.copyWith(
      takeoffWaitTimeSec: takeoffWaitTimeSec,
      takeoffFlightTimeSec: takeoffFlightTimeSec,
      landingConfirmTimeSec: landingConfirmTimeSec,
      minFlightSpeedMs: minFlightSpeedMs,
      maxWalkSpeedMs: maxWalkSpeedMs,
    );
  }
} // конец класса TrackConfigNotifier

final trackConfigProvider = StateNotifierProvider<TrackConfigNotifier, TrackConfig>((ref) {
  return TrackConfigNotifier(ref);
});
