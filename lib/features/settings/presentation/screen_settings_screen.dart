// Версия: 0.1.0 | Цель: Экран настроек дисплея (Ориентация, Wakelock)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/screen_settings_provider.dart';

class ScreenSettingsScreen extends ConsumerWidget {
  const ScreenSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrientation = ref.watch(orientationProvider);
    final isWakelockEnabled = ref.watch(wakelockProvider);

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
          RadioListTile<AppOrientation>(
            title: const Text('Системные настройки (Автоповорот)'),
            value: AppOrientation.system,
            groupValue: currentOrientation,
            onChanged: (val) {
              if (val != null) ref.read(orientationProvider.notifier).setOrientation(val);
            }, // конец onChanged
          ),
          RadioListTile<AppOrientation>(
            title: const Text('Портрет (Вертикально)'),
            value: AppOrientation.portrait,
            groupValue: currentOrientation,
            onChanged: (val) {
              if (val != null) ref.read(orientationProvider.notifier).setOrientation(val);
            }, // конец onChanged
          ),
          RadioListTile<AppOrientation>(
            title: const Text('Ландшафт (Горизонтально)'),
            value: AppOrientation.landscape,
            groupValue: currentOrientation,
            onChanged: (val) {
              if (val != null) ref.read(orientationProvider.notifier).setOrientation(val);
            }, // конец onChanged
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
            title: const Text('Always ON (Не гасить экран)'),
            subtitle: const Text('Запрещает дисплею выключаться в полете (Wakelock)'),
            value: isWakelockEnabled,
            onChanged: (val) {
              ref.read(wakelockProvider.notifier).toggle(val);
            }, // конец onChanged
          ),
        ],
      ), // конец ListView
    ); // конец Scaffold
  } // конец метода build
} // конец класса ScreenSettingsScreen
