// Версия: 0.4.0 | Цель: Главный экран настроек (Иерархия категорий)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Импорт будущих экранов категорий
import 'data_source_settings_screen.dart';

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
          // Новое: Элемент перехода к интерфейсу
          ListTile(
            leading: const Icon(Icons.display_settings),
            title: const Text('Интерфейс'),
            subtitle: const Text('Отображение HUD и графиков'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // В будущем переход на UISettingsScreen
            }, // конец onTap
          ), // конец ListTile
        ],
      ), // конец ListView
    ); // конец Scaffold
  } // конец метода build
} // конец класса SettingsScreen
