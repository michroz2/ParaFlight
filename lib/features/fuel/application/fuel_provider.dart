// Версия: 0.1.0 | Цель: Логика учета топлива и работа с SharedPreferences

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../domain/fuel_state.dart';
import '../../flight_detector/presentation/flight_detector_provider.dart';
import '../../flight_detector/domain/flight_state.dart';

class FuelNotifier extends StateNotifier<FuelState> {
  final SharedPreferences _prefs;

  static const String _keyEnableTracking = 'fuel_enable_tracking';
  static const String _keyAvgConsumption = 'fuel_average_consumption';
  static const String _keyRemainder = 'fuel_calculated_remainder';
  static const String _keyTankCapacity = 'fuel_tank_capacity';
  static const String _keyLastFlightDuration = 'fuel_last_flight_duration_hours';

  FuelNotifier(this._prefs) : super(const FuelState()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final enable = _prefs.getBool(_keyEnableTracking) ?? true;
    final avg = _prefs.getDouble(_keyAvgConsumption) ?? 4.0;
    final remainder = _prefs.getDouble(_keyRemainder) ?? 0.0;
    final capacity = _prefs.getDouble(_keyTankCapacity) ?? 15.0;
    final lastDuration = _prefs.getDouble(_keyLastFlightDuration) ?? 0.0;

    state = FuelState(
      enableFuelTracking: enable,
      averageConsumption: avg,
      remainder: remainder,
      tankCapacity: capacity,
      lastFlightDurationHours: lastDuration,
    );
  }

  Future<void> _saveToPrefs() async {
    await _prefs.setBool(_keyEnableTracking, state.enableFuelTracking);
    await _prefs.setDouble(_keyAvgConsumption, state.averageConsumption);
    await _prefs.setDouble(_keyRemainder, state.remainder);
    await _prefs.setDouble(_keyTankCapacity, state.tankCapacity);
    await _prefs.setDouble(_keyLastFlightDuration, state.lastFlightDurationHours);
  }

  void toggleTracking(bool enable) {
    state = state.copyWith(enableFuelTracking: enable);
    _saveToPrefs();
  }

  void updateFuel(double remainder, double added) {
    double newAvg = state.averageConsumption;

    // Расчет реального расхода и корректировка EMA
    if (remainder != state.remainder && state.lastFlightDurationHours > 0) {
      final realConsumption = (state.remainder - remainder) / state.lastFlightDurationHours;
      
      // Защита от сумасшедших значений
      if (realConsumption > 1.0 && realConsumption < 20.0) {
        newAvg = state.averageConsumption * 0.8 + realConsumption * 0.2;
      }
    }

    final newRemainder = remainder + added;
    
    state = state.copyWith(
      averageConsumption: newAvg,
      remainder: newRemainder,
      lastFlightDurationHours: 0.0, // Сбрасываем, так как корректировка учтена
    );
    
    _saveToPrefs();
  }

  void consumeInFlight(Duration dt) {
    if (dt.inMilliseconds <= 0) return;
    
    final hours = dt.inMilliseconds / 3600000.0;
    final consumed = state.averageConsumption * hours;
    var newRemainder = state.remainder - consumed;
    
    if (newRemainder < 0) newRemainder = 0;
    
    state = state.copyWith(remainder: newRemainder);
    // Для оптимизации мы не сохраняем в SharedPreferences каждый тик, 
    // сохранение будет происходить по триггеру (посадка или выход)
  }

  void recordFlightEnd(Duration flightDuration) {
    final hours = flightDuration.inMilliseconds / 3600000.0;
    state = state.copyWith(lastFlightDurationHours: hours);
    _saveToPrefs();
  }
  
  // Принудительное сохранение, например, при выходе из приложения (опционально)
  void forceSave() {
    _saveToPrefs();
  }
}

final fuelProvider = StateNotifierProvider<FuelNotifier, FuelState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final notifier = FuelNotifier(prefs);

  ref.listen(flightDetectorProvider, (previous, next) {
    if (previous == null) return;
    
    // Расход топлива в полете
    if (next.state == FlightState.inFlight) {
      final dt = next.currentDuration - previous.currentDuration;
      if (dt.inMilliseconds > 0) {
        notifier.consumeInFlight(dt);
      }
    }
    
    // Сохранение при посадке (переход из inFlight в другое состояние)
    if (previous.state == FlightState.inFlight && next.state != FlightState.inFlight) {
      if (next.flights.isNotEmpty) {
        notifier.recordFlightEnd(next.flights.last.duration);
      }
    }
  });

  return notifier;
});
