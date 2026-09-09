// =============================================================================
// Файл:    fuel_provider.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Логика учета топлива и работа с SharedPreferences
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/preferences/preferences_provider.dart';
import '../../../core/location/location_state.dart';
import '../../../core/location/location_state.dart';
import '../domain/fuel_state.dart';
import '../../flight_detector/presentation/flight_detector_provider.dart';
import '../../flight_detector/domain/flight_state.dart';

class FuelNotifier extends StateNotifier<FuelState> {
  final SharedPreferences _prefs;

  static const String _keyEnableTracking = 'fuel_enable_tracking';
  static const String _keyAutoCorrect = 'fuel_auto_correct';
  static const String _keyCorrectInSimulator = 'fuel_correct_in_simulator';
  static const String _keyAvgConsumption = 'fuel_average_consumption';
  static const String _keyRemainder = 'fuel_calculated_remainder';
  static const String _keyTankCapacity = 'fuel_tank_capacity';
  static const String _keyJokerRemainder = 'fuel_joker_remainder';
  static const String _keyLastFlightDuration = 'fuel_last_flight_duration_hours';

  FuelNotifier(this._prefs) : super(const FuelState()) {
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    final enable = _prefs.getBool(_keyEnableTracking) ?? true;
    final autoCorrect = _prefs.getBool(_keyAutoCorrect) ?? true;
    final correctInSim = _prefs.getBool(_keyCorrectInSimulator) ?? false;
    final avg = _prefs.getDouble(_keyAvgConsumption) ?? 4.0;
    final remainder = _prefs.getDouble(_keyRemainder) ?? 0.0;
    final capacity = _prefs.getDouble(_keyTankCapacity) ?? 15.0;
    final joker = _prefs.getDouble(_keyJokerRemainder) ?? 2.0;
    final lastDuration = _prefs.getDouble(_keyLastFlightDuration) ?? 0.0;

    state = FuelState(
      enableFuelTracking: enable,
      autoCorrectConsumption: autoCorrect,
      correctInSimulator: correctInSim,
      averageConsumption: avg,
      remainder: remainder,
      tankCapacity: capacity,
      jokerRemainder: joker,
      lastFlightDurationHours: lastDuration,
    );
  }

  Future<void> _saveToPrefs() async {
    await _prefs.setBool(_keyEnableTracking, state.enableFuelTracking);
    await _prefs.setBool(_keyAutoCorrect, state.autoCorrectConsumption);
    await _prefs.setBool(_keyCorrectInSimulator, state.correctInSimulator);
    await _prefs.setDouble(_keyAvgConsumption, state.averageConsumption);
    await _prefs.setDouble(_keyRemainder, state.remainder);
    await _prefs.setDouble(_keyTankCapacity, state.tankCapacity);
    await _prefs.setDouble(_keyJokerRemainder, state.jokerRemainder);
    await _prefs.setDouble(_keyLastFlightDuration, state.lastFlightDurationHours);
  }

  void toggleTracking(bool enable) {
    state = state.copyWith(enableFuelTracking: enable);
    _saveToPrefs();
  }

  void toggleAutoCorrect(bool enable) {
    state = state.copyWith(autoCorrectConsumption: enable);
    _saveToPrefs();
  }

  void toggleCorrectInSimulator(bool enable) {
    state = state.copyWith(correctInSimulator: enable);
    _saveToPrefs();
  }

  void setAverageConsumption(double consumption) {
    state = state.copyWith(averageConsumption: consumption);
    _saveToPrefs();
  }

  void setTankCapacity(double capacity) {
    state = state.copyWith(tankCapacity: capacity);
    _saveToPrefs();
  }
  
  void setJokerRemainder(double joker) {
    state = state.copyWith(jokerRemainder: joker);
    _saveToPrefs();
  }

  void markJokerWarningShown() {
    state = state.copyWith(hasShownJokerWarning: true);
  }

  void updateFuel(double remainder, double added, bool isSimulator) {
    double newAvg = state.averageConsumption;
    double newLastFlightDuration = state.lastFlightDurationHours;

    final shouldCorrect = state.autoCorrectConsumption && (!isSimulator || state.correctInSimulator);

    // Расчет реального расхода
    if (shouldCorrect && remainder != state.remainder && state.lastFlightDurationHours > 0) {
      final realConsumption = state.averageConsumption + ((state.remainder - remainder) / state.lastFlightDurationHours);
      
      // Защита от сумасшедших значений и ограничение максимума в 15 л/ч
      if (realConsumption > 15.0) {
        newAvg = 15.0;
      } else if (realConsumption >= 1.0) {
        newAvg = realConsumption;
      }
      
      // По запросу: время полёта остаётся постоянным, не сбрасываем.
      // newLastFlightDuration = 0.0;
    }

    final newRemainder = remainder + added;
    
    state = state.copyWith(
      averageConsumption: newAvg,
      remainder: newRemainder,
      lastFlightDurationHours: newLastFlightDuration,
      // Сбрасываем флаг показа предупреждения, если топлива стало больше рубежного
      hasShownJokerWarning: newRemainder > state.jokerRemainder ? false : state.hasShownJokerWarning,
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

  void recordFlightEnd(Duration flightDuration, bool isSimulator) {
    if (isSimulator && !state.correctInSimulator) {
      return; // Не записываем данные крайнего полета при симуляции, если настройка отключена
    }

    final hours = flightDuration.inMilliseconds / 3600000.0;
    state = state.copyWith(
      lastFlightDurationHours: hours,
      hasShownJokerWarning: false, // Сбрасываем флаг при завершении полета
    );
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
        final isSim = ref.read(dataSourceProvider) == DataSource.simulator;
        notifier.recordFlightEnd(next.flights.last.duration, isSim);
      }
    }
  });

  return notifier;
});
