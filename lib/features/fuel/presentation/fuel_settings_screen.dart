import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/fuel_provider.dart';

class FuelSettingsScreen extends ConsumerWidget {
  const FuelSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelState = ref.watch(fuelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расчёт топлива'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Учитывать топливо'),
            subtitle: const Text('Отображать расчет на главном экране'),
            value: fuelState.enableFuelTracking,
            onChanged: (val) {
              ref.read(fuelProvider.notifier).toggleTracking(val);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Расход (л/ч)'),
            subtitle: Text(fuelState.averageConsumption.toStringAsFixed(1)),
            enabled: fuelState.enableFuelTracking,
            // Здесь в будущем можно добавить диалог для ручного изменения расхода,
            // но пока оставим просто для информации или добавим логику
          ),
          ListTile(
            title: const Text('Ёмкость бака (л)'),
            subtitle: Text(fuelState.tankCapacity.toStringAsFixed(1)),
            enabled: fuelState.enableFuelTracking,
          ),
        ],
      ),
    );
  }
}
