// Версия: 0.2.0 | Цель: Модель состояния топлива
class FuelState {
  final bool enableFuelTracking;
  final bool autoCorrectConsumption;
  final bool correctInSimulator;
  final double averageConsumption; // л/ч
  final double remainder; // л
  final double tankCapacity; // л
  final double lastFlightDurationHours; // ч

  const FuelState({
    this.enableFuelTracking = true,
    this.autoCorrectConsumption = true,
    this.correctInSimulator = false,
    this.averageConsumption = 4.0,
    this.remainder = 0.0,
    this.tankCapacity = 15.0,
    this.lastFlightDurationHours = 0.0,
  });

  FuelState copyWith({
    bool? enableFuelTracking,
    bool? autoCorrectConsumption,
    bool? correctInSimulator,
    double? averageConsumption,
    double? remainder,
    double? tankCapacity,
    double? lastFlightDurationHours,
  }) {
    return FuelState(
      enableFuelTracking: enableFuelTracking ?? this.enableFuelTracking,
      autoCorrectConsumption: autoCorrectConsumption ?? this.autoCorrectConsumption,
      correctInSimulator: correctInSimulator ?? this.correctInSimulator,
      averageConsumption: averageConsumption ?? this.averageConsumption,
      remainder: remainder ?? this.remainder,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      lastFlightDurationHours: lastFlightDurationHours ?? this.lastFlightDurationHours,
    );
  }
}
