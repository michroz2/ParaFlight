// Версия: 0.3.0 | Цель: Точка входа в приложение и инициализация глобальных сервисов

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/preferences/preferences_provider.dart';
import 'core/location/tracks_manager.dart';
import 'features/settings/application/screen_settings_provider.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'core/location/flight_path_state.dart';
import 'features/flight_detector/presentation/flight_detector_provider.dart';

void main() async {
  // Гарантируем инициализацию Flutter-биндингов до асинхронных вызовов
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация SharedPreferences до старта UI
  final sharedPreferences = await SharedPreferences.getInstance();

  // Инициализация TracksManager (копирование треков из ресурсов)
  final tracksManager = TracksManager();
  await tracksManager.initialize(sharedPreferences);

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      tracksManagerProvider.overrideWithValue(tracksManager),
    ],
  );

  // Форсированно запускаем трекинг и детектор вне дерева виджетов
  container.read(realGpsTrackProvider);
  container.read(flightDetectorProvider);
  
  // Вешаем слушателей прямо на контейнер, чтобы они никогда не засыпали
  container.listen(realGpsTrackProvider, (prev, next) {});
  container.listen(flightDetectorProvider, (prev, next) {});

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ParaFlightApp(),
    ), // конец UncontrolledProviderScope
  ); // конец runApp
} // конец main

// ParaFlightApp теперь ConsumerWidget для прослушивания настроек экрана при старте
class ParaFlightApp extends ConsumerWidget {
  const ParaFlightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Читаем провайдеры при старте, чтобы они инициализировались 
    // и применили свои _applyState() (Ориентация и Wakelock)
    ref.watch(wakelockProvider);
    ref.watch(orientationProvider);

    return const MaterialApp(
      title: 'ParaFlight',
      home: DashboardScreen(),
    ); // конец MaterialApp
  } // конец метода build
} // конец класса ParaFlightApp
