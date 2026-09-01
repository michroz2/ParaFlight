// Версия: 0.1.0 | Цель: Экран настройки параметров карты и таймеров

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/map_settings_provider.dart';

class MapSettingsScreen extends ConsumerWidget {
  const MapSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(mapSettingsProvider);
    final notifier = ref.read(mapSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление картой'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Автоскрытие интерфейса',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('Через ${settings.uiAutoHideSeconds} сек. бездействия'),
          Slider(
            value: settings.uiAutoHideSeconds.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            label: '${settings.uiAutoHideSeconds} с',
            onChanged: (value) {
              notifier.setUiAutoHide(value.toInt());
            },
          ),
          const Divider(height: 32),

          const Text(
            'Автовозврат карты к пилоту',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('Через ${settings.mapAutoCenterSeconds} сек. после ручного сдвига карты'),
          Slider(
            value: settings.mapAutoCenterSeconds.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            label: '${settings.mapAutoCenterSeconds} с',
            onChanged: (value) {
              notifier.setMapAutoCenter(value.toInt());
            },
          ),
          const Divider(height: 32),

          const Text(
            'Компас по умолчанию',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          RadioListTile<MapRotationMode>(
            title: const Text('Север сверху (North Up)'),
            value: MapRotationMode.north,
            groupValue: settings.defaultRotationMode,
            onChanged: (value) {
              if (value != null) notifier.setDefaultRotation(value);
            },
          ),
          RadioListTile<MapRotationMode>(
            title: const Text('По курсу (Track Up)'),
            value: MapRotationMode.heading,
            groupValue: settings.defaultRotationMode,
            onChanged: (value) {
              if (value != null) notifier.setDefaultRotation(value);
            },
          ),
        ],
      ), // конец ListView
    ); // конец Scaffold
  } // конец метода build
} // конец класса MapSettingsScreen
