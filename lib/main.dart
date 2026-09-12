// =============================================================================
// Файл:    main.dart
// Проект:  ParaFlight
// Версия:  0.3.1
// Цель:    Точка входа в приложение и инициализация глобальных сервисов
// Изменения:
//   0.3.0 - Инициализация глобальных сервисов и провайдеров при запуске
//   0.3.1 - Изменение: удален отладочный Timer.periodic
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'core/preferences/preferences_provider.dart';
import 'core/storage/local_storage_service.dart'; // Новое: Импорт сервиса локального хранилища
import 'features/settings/application/screen_settings_provider.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'core/location/flight_path_state.dart';
import 'features/flight_detector/presentation/flight_detector_provider.dart';
import 'features/settings/application/cockpit_mode_controller.dart'; // Новое: импорт контроллера Кокпита
import 'features/settings/application/advanced_mode_provider.dart';
import 'core/location/location_state.dart';

void main() async {
  // Гарантируем инициализацию Flutter-биндингов до асинхронных вызовов
  WidgetsFlutterBinding.ensureInitialized();
  
  // Изменение: Удален отладочный Timer.periodic, чтобы не спамить в логах продакшена
  
  // Инициализация SharedPreferences до старта UI
  final sharedPreferences = await SharedPreferences.getInstance();

  // Изменение: Инициализация LocalStorageService вместо TracksManager
  final localStorage = LocalStorageService();
  await localStorage.init();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      localStorageProvider.overrideWithValue(localStorage), // Новое: провайдер хранилища
    ],
  );

  // Форсированно запускаем трекинг и детектор вне дерева виджетов
  container.read(realGpsTrackProvider);
  container.read(flightDetectorProvider);
  container.read(cockpitModeControllerProvider);
  
  // Вешаем слушателей прямо на контейнер, чтобы они никогда не засыпали
  container.listen(realGpsTrackProvider, (prev, next) {});
  container.listen(flightDetectorProvider, (prev, next) {});
  container.listen(cockpitModeControllerProvider, (prev, next) {});
  container.listen(dataSourceProvider, (prev, next) {
    if (next == DataSource.internalGps) {
      container.read(advancedModeProvider.notifier).reset();
    }
  });

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
