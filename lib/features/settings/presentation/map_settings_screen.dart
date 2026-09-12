// =============================================================================
// Файл:    map_settings_screen.dart
// Проект:  ParaFlight
// Версия:  0.1.0
// Цель:    Экран настройки параметров карты и таймеров
// Изменения:
//   0.1.0 - Первичная реализация
// =============================================================================

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
            'Органы управления по нажатию',
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
            'Автоцентровка карты',
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
          // Изменение: RadioListTile.groupValue/onChanged устарели с Flutter 3.32 → используем RadioGroup
          RadioGroup<MapRotationMode>(
            groupValue: settings.defaultRotationMode,
            onChanged: (value) {
              if (value != null) notifier.setDefaultRotation(value);
            },
            child: Column(
              children: [
                RadioListTile<MapRotationMode>(
                  title: const Text('Север сверху (North Up)'),
                  value: MapRotationMode.north,
                ),
                RadioListTile<MapRotationMode>(
                  title: const Text('По курсу (Track Up)'),
                  value: MapRotationMode.heading,
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          const Text(
            'Отображение',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          // Новое: Настройка указателя на старт
          SwitchListTile(
            title: const Text('Показывать направление на старт'),
            value: settings.enableStartPointer,
            onChanged: (value) => ref.read(mapSettingsProvider.notifier).setEnableStartPointer(value),
          ),
        ],
      ), // конец ListView
    ); // конец Scaffold
  } // конец метода build
} // конец класса MapSettingsScreen
