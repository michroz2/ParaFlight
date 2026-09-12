// =============================================================================
// Файл:    about_screen.dart
// Проект:  ParaFlight
// Цель:    Экран О приложении и Factory Reset
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/preferences/preferences_provider.dart';
import '../../../core/version_provider.dart';
import '../application/advanced_mode_provider.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdvanced = ref.watch(advancedModeProvider);
    final versionAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('О приложении'),
        backgroundColor: Colors.amber,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Автономный полетный компьютер для пилотов парамоторов.\n\nРазработан для обеспечения информационного комфорта в полете: предоставляет навигацию: блок приборов, карту и трек, расчет расхода топлива и вычисление амбиентного ветра.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            versionAsync.when(
              data: (info) => Text(
                'Версия: ${info.version}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Ошибка загрузки версии: $err'),
            ),
            const Spacer(),
            if (isAdvanced)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => _showFactoryResetDialog(context, ref),
                child: const Text('СБРОСИТЬ НАСТРОЙКИ НА ЗАВОДСКИЕ'),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _showFactoryResetDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сброс настроек'),
        content: const Text('Вы уверены? Это сотрет все настройки и вернет их к заводским значениям.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Да, сбросить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = ref.read(sharedPreferencesProvider);
      final currentGpx = prefs.getString('selected_gpx_file');
      await prefs.clear();
      if (currentGpx != null) {
        await prefs.setString('selected_gpx_file', currentGpx);
      }
      SystemNavigator.pop();
    }
  }
}
