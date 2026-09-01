// Версия: 0.5.1 | Цель: Главный экран настроек (Иерархия категорий)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Импорт будущих экранов категорий
import 'data_source_settings_screen.dart';
import 'screen_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          // Новое: Элемент перехода к источнику данных
          ListTile(
            leading: const Icon(Icons.satellite_alt),
            title: const Text('Источник данных'),
            subtitle: const Text('GPS, Внешние датчики, Симулятор'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const DataSourceSettingsScreen()),
              );
            }, // конец onTap
          ), // конец ListTile
          const Divider(),
          // Новое: Элемент перехода к ветру
          ListTile(
            leading: const Icon(Icons.air),
            title: const Text('Параметры ветра'),
            subtitle: const Text('Чувствительность, размеры буфера'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // В будущем переход на WindSettingsScreen
            }, // конец onTap
          ), // конец ListTile
          const Divider(),
          // Новое: Элемент перехода к настройкам экрана
          ListTile(
            leading: const Icon(Icons.display_settings),
            title: const Text('Экран'),
            subtitle: const Text('Ориентация, Wakelock'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScreenSettingsScreen()),
              );
            }, // конец onTap
          ), // конец ListTile
          const Divider(),
          // Новое: Элемент Выхода из приложения
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Выход', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Закрыть приложение'),
            onTap: () {
              SystemNavigator.pop();
            }, // конец onTap
          ), // конец ListTile
        ],
      ), // конец ListView
    ); // конец Scaffold
  } // конец метода build
} // конец класса SettingsScreen
