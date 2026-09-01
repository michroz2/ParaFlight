// Версия: 0.2.0 | Цель: Точка входа в приложение и инициализация глобальных сервисов

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/preferences/preferences_provider.dart';
import 'features/settings/application/screen_settings_provider.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';

void main() async {
  // Новое: Гарантируем инициализацию Flutter-биндингов до асинхронных вызовов
  WidgetsFlutterBinding.ensureInitialized();
  
  // Изменение: Инициализируем SharedPreferences до старта UI
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Передаем реальный инстанс в провайдер-заглушку
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const ParaFlightApp(),
    ), // конец ProviderScope
  ); // конец runApp
} // конец main

// Изменение: ParaFlightApp теперь ConsumerWidget для прослушивания настроек экрана при старте
class ParaFlightApp extends ConsumerWidget {
  const ParaFlightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Новое: Читаем провайдеры при старте, чтобы они инициализировались 
    // и применили свои _applyState() (Ориентация и Wakelock)
    ref.watch(wakelockProvider);
    ref.watch(orientationProvider);

    return const MaterialApp(
      title: 'ParaFlight',
      home: DashboardScreen(),
    ); // конец MaterialApp
  } // конец метода build
} // конец класса ParaFlightApp
