// =============================================================================
// Файл:    screen_settings_screen.dart
// Проект:  ParaFlight
// Версия:  0.2.0
// Цель:    Экран настроек дисплея (Ориентация, Wakelock, Режим Кокпита)
// Изменения:
//   0.2.0 - Первичная реализация
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/screen_settings_provider.dart';

class ScreenSettingsScreen extends ConsumerWidget {
  const ScreenSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrientation = ref.watch(orientationProvider);
    final isWakelockEnabled = ref.watch(wakelockProvider);
    final isCockpitModeEnabled = ref.watch(cockpitModeProvider); // Новое: читаем состояние тумблера

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки экрана'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Ориентация дисплея',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          // Изменение: RadioListTile.groupValue/onChanged устарели с Flutter 3.32 → используем RadioGroup
          RadioGroup<AppOrientation>(
            groupValue: currentOrientation,
            onChanged: (val) {
              if (val != null) ref.read(orientationProvider.notifier).setOrientation(val);
            },
            child: Column(
              children: [
                RadioListTile<AppOrientation>(
                  title: const Text('Системные настройки (Автоповорот)'),
                  value: AppOrientation.system,
                ),
                RadioListTile<AppOrientation>(
                  title: const Text('Портрет (Вертикально)'),
                  value: AppOrientation.portrait,
                ),
                RadioListTile<AppOrientation>(
                  title: const Text('Ландшафт (Горизонтально)'),
                  value: AppOrientation.landscape,
                ),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Энергосбережение',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          SwitchListTile(
            title: const Text('Постоянный дисплей'),
            subtitle: const Text('Запрещает дисплею выключаться в полете'),
            value: isWakelockEnabled,
            onChanged: (val) {
              ref.read(wakelockProvider.notifier).toggle(val);
            }, // конец onChanged
          ),
          const Divider(),
          // Новое: Секция Безопасности
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Безопасность',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          // Новое: Тумблер Режима Кокпита
          SwitchListTile(
            title: const Text('Защита от случайного выхода'),
            subtitle: const Text('Блокирует системные жесты и кнопки. Работает только при Встроенном GPS'),
            value: isCockpitModeEnabled,
            onChanged: (val) {
              ref.read(cockpitModeProvider.notifier).toggle(val);
            }, // конец onChanged
          ),
        ],
      ), // конец ListView
    ); // конец Scaffold
  } // конец метода build
} // конец класса ScreenSettingsScreen
