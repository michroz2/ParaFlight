// =============================================================================
// Файл:    wind_settings_screen.dart
// Проект:  ParaFlight
// Версия:  0.2.0
// Цель:    Экран настроек параметров ветра
// Изменения:
//   0.1.0 - Первичная реализация
//   0.2.0 - Добавлены ползунки для Roundness, RMSE и Min Buffer
// =============================================================================

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
          const Text('Отображение', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          // Новое: Тумблер для графической стрелки
          SwitchListTile(
            title: const Text('Показывать стрелку ветра'),
            value: config.enableWindArrow,
            onChanged: (value) => notifier.updateConfig(enableWindArrow: value),
          ),
          // Изменение: Отвязанная телеметрия
          SwitchListTile(
            title: const Text('Показывать телеметрию'), // Изменили текст
            value: config.enableWindOverlay,
            onChanged: (value) => notifier.updateConfig(enableWindOverlay: value),
          ),
          ListTile(
            title: const Text('Инерция прибора (EMA)'),
            subtitle: Text('${config.windEmaAlpha.toStringAsFixed(1)} (Плавнее <-> Без фильтра)'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: config.windEmaAlpha,
                min: 0.2,
                max: 1.0,
                divisions: 8,
                label: config.windEmaAlpha.toStringAsFixed(1),
                onChanged: (value) => notifier.updateConfig(windEmaAlpha: value),
              ),
            ),
          ),
          const Divider(),
          const Text('Анализ трека', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
            title: const Text('Необходимый угол поворота (°)'),
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
          const Text('Окно балансировочной скорости', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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

          // Новое: Секция настроек валидации
          const Divider(height: 32),
          const Text('Валидация', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),

          ListTile(
            title: const Text('Индекс круглости (защита от прямой)'),
            subtitle: Text(config.minRoundness.toStringAsFixed(1)),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: config.minRoundness,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: config.minRoundness.toStringAsFixed(1),
                onChanged: (value) => notifier.updateConfig(minRoundness: value),
              ),
            ),
          ),
          ListTile(
            title: const Text('Макс. погрешность (RMSE)'),
            subtitle: Text('${config.maxRmseMs.toStringAsFixed(1)} м/с'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: config.maxRmseMs,
                min: 0.5,
                max: 3.0,
                divisions: 25,
                label: config.maxRmseMs.toStringAsFixed(1),
                onChanged: (value) => notifier.updateConfig(maxRmseMs: value),
              ),
            ),
          ),
          ListTile(
            title: const Text('Мин. размер буфера'),
            subtitle: Text('${config.minBufferPoints} точек'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: config.minBufferPoints.toDouble(),
                min: 10.0,
                max: 120.0,
                divisions: 22,
                label: config.minBufferPoints.toString(),
                onChanged: (value) => notifier.updateConfig(minBufferPoints: value.toInt()),
              ),
            ),
          ),
        ],
      ),
    );
  }
} // конец класса WindSettingsScreen
