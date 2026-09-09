// =============================================================================
// Файл:    fuel_settings_screen.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Экран настроек учета расхода топлива
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/fuel_provider.dart';

class FuelSettingsScreen extends ConsumerWidget {
  const FuelSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelState = ref.watch(fuelProvider);
    final notifier = ref.read(fuelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расчёт топлива'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Учитывать топливо'),
            subtitle: const Text('Отображать запас и корректировать расход'),
            value: fuelState.enableFuelTracking,
            onChanged: (val) {
              notifier.toggleTracking(val);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Ёмкость бака (л)'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fuelState.tankCapacity.toStringAsFixed(1)),
                Slider(
                  value: fuelState.tankCapacity,
                  min: 0,
                  max: 30,
                  divisions: 60,
                  label: fuelState.tankCapacity.toStringAsFixed(1),
                  onChanged: fuelState.enableFuelTracking
                      ? (val) => notifier.setTankCapacity(val)
                      : null,
                ),
              ],
            ),
            enabled: fuelState.enableFuelTracking,
          ),
          const Divider(),
          ListTile(
            title: const Text('Расход (л/ч)'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fuelState.averageConsumption.toStringAsFixed(1)),
                Slider(
                  value: fuelState.averageConsumption,
                  min: 0,
                  max: 15,
                  divisions: 30,
                  label: fuelState.averageConsumption.toStringAsFixed(1),
                  onChanged: fuelState.enableFuelTracking
                      ? (val) => notifier.setAverageConsumption(val)
                      : null,
                ),
              ],
            ),
            enabled: fuelState.enableFuelTracking,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Корректировать расход автоматически'),
            subtitle: const Text('Пересчитывать расход путём коррекции остатка'),
            value: fuelState.autoCorrectConsumption,
            onChanged: fuelState.enableFuelTracking
                ? (val) => notifier.toggleAutoCorrect(val)
                : null,
          ),
          SwitchListTile(
            title: const Text('Корректировать при симуляции'),
            subtitle: const Text('Пересчитывать расход во время использования симулятора'),
            value: fuelState.correctInSimulator,
            onChanged: fuelState.enableFuelTracking
                ? (val) => notifier.toggleCorrectInSimulator(val)
                : null,
          ),
          const Divider(),
          ListTile(
            title: const Text('Рубежный остаток (л)'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fuelState.jokerRemainder.toStringAsFixed(1)),
                Slider(
                  value: fuelState.jokerRemainder,
                  min: 0,
                  max: 5,
                  divisions: 50,
                  label: fuelState.jokerRemainder.toStringAsFixed(1),
                  onChanged: fuelState.enableFuelTracking
                      ? (val) => notifier.setJokerRemainder(val)
                      : null,
                ),
              ],
            ),
            enabled: fuelState.enableFuelTracking,
          ),
        ],
      ),
    );
  }
}
