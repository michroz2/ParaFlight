// Версия: 0.1.0 | Цель: Экран настройки панели инструментов (Дашборда)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/dashboard_config_provider.dart';

class DashboardSettingsScreen extends ConsumerWidget {
  const DashboardSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(dashboardConfigProvider);
    final notifier = ref.read(dashboardConfigProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель инструментов'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Сглаживание вариометра (Vz)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Большее значение окна дает более плавный, но более "задумчивый" результат.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text('Окно сглаживания: ${settings.vzWindowSec} сек.'),
          Slider(
            value: settings.vzWindowSec.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            label: '${settings.vzWindowSec} с',
            onChanged: (value) {
              notifier.setVzWindowSec(value.toInt());
            },
          ),
        ],
      ), // конец ListView
    ); // конец Scaffold
  } // конец метода build
} // конец класса DashboardSettingsScreen
