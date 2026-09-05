// Версия: 0.2.0 | Цель: Модель состояния топлива
class FuelState {
  final bool enableFuelTracking;
  final bool autoCorrectConsumption;
  final bool correctInSimulator;
  final double averageConsumption; // л/ч
  final double remainder; // л
  final double tankCapacity; // л
  final double jokerRemainder; // л (Рубежный остаток)
  final double lastFlightDurationHours; // ч
  final bool hasShownJokerWarning;

  const FuelState({
    this.enableFuelTracking = true,
    this.autoCorrectConsumption = true,
    this.correctInSimulator = false,
    this.averageConsumption = 4.0,
    this.remainder = 0.0,
    this.tankCapacity = 15.0,
    this.jokerRemainder = 2.0,
    this.lastFlightDurationHours = 0.0,
    this.hasShownJokerWarning = false,
  });

  FuelState copyWith({
    bool? enableFuelTracking,
    bool? autoCorrectConsumption,
    bool? correctInSimulator,
    double? averageConsumption,
    double? remainder,
    double? tankCapacity,
    double? jokerRemainder,
    double? lastFlightDurationHours,
    bool? hasShownJokerWarning,
  }) {
    return FuelState(
      enableFuelTracking: enableFuelTracking ?? this.enableFuelTracking,
      autoCorrectConsumption: autoCorrectConsumption ?? this.autoCorrectConsumption,
      correctInSimulator: correctInSimulator ?? this.correctInSimulator,
      averageConsumption: averageConsumption ?? this.averageConsumption,
      remainder: remainder ?? this.remainder,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      jokerRemainder: jokerRemainder ?? this.jokerRemainder,
      lastFlightDurationHours: lastFlightDurationHours ?? this.lastFlightDurationHours,
      hasShownJokerWarning: hasShownJokerWarning ?? this.hasShownJokerWarning,
    );
  }
}
