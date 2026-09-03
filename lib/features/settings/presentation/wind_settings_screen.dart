// Версия: 0.1.0 | Цель: Экран настроек параметров ветра

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/application/wind_config_provider.dart';

class WindSettingsScreen extends ConsumerWidget {
  const WindSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(windConfigProvider);
    final notifier = ref.read(windConfigProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Параметры ветра'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Анализ трека (Конвейер)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 8),
          
          ListTile(
            title: const Text('Размер окна (сек)'),
            subtitle: Text(config.windowSizeSec.toStringAsFixed(0)),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: config.windowSizeSec,
                min: 30,
                max: 300,
                divisions: 27,
                label: config.windowSizeSec.toStringAsFixed(0),
                onChanged: (value) => notifier.updateConfig(windowSizeSec: value),
              ),
            ),
          ),
          ListTile(
            title: const Text('Мин. угол поворота (°)'),
            subtitle: Text(config.minTurnAngleDeg.toStringAsFixed(0)),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: config.minTurnAngleDeg,
                min: 10,
                max: 180,
                divisions: 34,
                label: config.minTurnAngleDeg.toStringAsFixed(0),
                onChanged: (value) => notifier.updateConfig(minTurnAngleDeg: value),
              ),
            ),
          ),
          
          const Divider(height: 32),
          const Text('Жесткий коридор (Airspeed Validator)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
          const SizedBox(height: 8),

          ListTile(
            title: const Text('Мин. скорость (м/с)'),
            subtitle: Text('${config.minAirspeedMs.toStringAsFixed(1)} (~${(config.minAirspeedMs * 3.6).toStringAsFixed(0)} км/ч)'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: config.minAirspeedMs,
                min: 2.0,
                max: 15.0,
                divisions: 26,
                label: config.minAirspeedMs.toStringAsFixed(1),
                onChanged: (value) => notifier.updateConfig(minAirspeedMs: value),
              ),
            ),
          ),
          ListTile(
            title: const Text('Макс. скорость (м/с)'),
            subtitle: Text('${config.maxAirspeedMs.toStringAsFixed(1)} (~${(config.maxAirspeedMs * 3.6).toStringAsFixed(0)} км/ч)'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: config.maxAirspeedMs,
                min: 10.0,
                max: 30.0,
                divisions: 40,
                label: config.maxAirspeedMs.toStringAsFixed(1),
                onChanged: (value) => notifier.updateConfig(maxAirspeedMs: value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
