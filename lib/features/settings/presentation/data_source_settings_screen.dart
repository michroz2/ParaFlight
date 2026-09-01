// Версия: 0.4.0 | Цель: Экран выбора источника данных (GPS/Симулятор)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DataSourceSettingsScreen extends ConsumerWidget {
  const DataSourceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Источник данных'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          // Новое: Заглушка текста
          Text(
            'Настройки источника данных в разработке.\n\n'
            'Здесь будет располагаться переключатель между внутренним GPS, '
            'внешними BLE-датчиками и файлом симуляции (mock_flight.gpx).',
            style: TextStyle(fontSize: 16),
          ), // конец Text
        ],
      ), // конец ListView
    ); // конец Scaffold
  } // конец метода build
} // конец класса DataSourceSettingsScreen
