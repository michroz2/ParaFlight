// Версия: 0.5.0 | Цель: Экран выбора источника данных (GPS/Симулятор)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/location/location_state.dart';

class DataSourceSettingsScreen extends ConsumerWidget {
  const DataSourceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSource = ref.watch(dataSourceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Источник данных'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          // Новое: Радиокнопка Симулятора
          RadioListTile<DataSource>(
            title: const Text('Симулятор (mock_flight.gpx)'),
            subtitle: const Text('Воспроизведение записанного трека с симуляцией времени'),
            value: DataSource.simulator,
            groupValue: currentSource,
            onChanged: (DataSource? value) {
              if (value != null) {
                ref.read(dataSourceProvider.notifier).setSource(value);
              } // конец if
            }, // конец onChanged
          ), // конец RadioListTile

          // Новое: Радиокнопка встроенного GPS
          RadioListTile<DataSource>(
            title: const Text('Встроенный GPS смартфона'),
            subtitle: const Text('Использование аппаратного датчика геолокации устройства'),
            value: DataSource.internalGps,
            groupValue: currentSource,
            onChanged: (DataSource? value) {
              if (value != null) {
                ref.read(dataSourceProvider.notifier).setSource(value);
              } // конец if
            }, // конец onChanged
          ), // конец RadioListTile
        ],
      ), // конец ListView
    ); // конец Scaffold
  } // конец метода build
} // конец класса DataSourceSettingsScreen
